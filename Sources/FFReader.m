#import "FFReader.h"
#import <mach/mach.h>
#import <mach/mach_vm.h>
#import <mach-o/loader.h>
#import <sys/sysctl.h>
#import <errno.h>
#import <string.h>
#import <stdlib.h>

static BOOL ReadBytes(mach_port_t task, uint64_t address, void *buffer, size_t size) {
    mach_vm_size_t actual = 0;
    return mach_vm_read_overwrite(task, address, size, (mach_vm_address_t)buffer, &actual) == KERN_SUCCESS && actual == size;
}
static BOOL Pointer(uint64_t p) { return p >= 0x100000000ULL && p < 0x1000000000000ULL && !(p & 7); }
static NSString *Hex(uint64_t n) { return [NSString stringWithFormat:@"0x%llx", (unsigned long long)n]; }
static pid_t GamePID(int *error) {
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0}; size_t size = 0;
    if (sysctl(mib, 4, NULL, &size, NULL, 0)) { *error = errno; return 0; }
    for (int attempt = 0; attempt < 3; attempt++) {
        size_t capacity = size + 32 * sizeof(struct kinfo_proc);
        struct kinfo_proc *list = calloc(1, capacity);
        if (!list) { *error = ENOMEM; return 0; }
        if (sysctl(mib, 4, list, &capacity, NULL, 0) == 0) {
            pid_t found = 0;
            for (size_t i = 0; i < capacity / sizeof(*list); i++)
                if (strcmp(list[i].kp_proc.p_comm, "FreeFireMAX") == 0) { found = list[i].kp_proc.p_pid; break; }
            free(list); return found;
        }
        *error = errno; free(list); if (*error != ENOMEM) return 0;
        if (sysctl(mib, 4, NULL, &size, NULL, 0)) { *error = errno; return 0; }
    }
    return 0;
}
// iOS arm64 layouts: first fields of dyld_all_image_infos and dyld_image_info.
typedef struct { uint32_t version, count; uint64_t array; } ImageHeader;
typedef struct { uint64_t load, path, modified; } Image;
static uint64_t UnityBase(mach_port_t task) {
    struct task_dyld_info info = {0}; mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    if (task_info(task, TASK_DYLD_INFO, (task_info_t)&info, &count) != KERN_SUCCESS) return 0;
    if (info.all_image_info_format != TASK_DYLD_ALL_IMAGE_INFO_64) return 0;
    ImageHeader head = {0};
    if (!ReadBytes(task, info.all_image_info_addr, &head, sizeof(head)) || head.count == 0 || head.count > 4096 || !Pointer(head.array)) return 0;
    Image *images = calloc(head.count, sizeof(Image)); if (!images) return 0;
    uint64_t base = 0;
    if (ReadBytes(task, head.array, images, head.count * sizeof(Image))) {
        for (uint32_t i = 0; i < head.count; i++) {
            char path[1024] = {0}; size_t pos = 0;
            // Byte reads avoid crossing into an unmapped page after a short string.
            for (; pos < sizeof(path)-1; pos++) {
                if (!ReadBytes(task, images[i].path + pos, &path[pos], 1)) break;
                if (!path[pos]) break;
            }
            if (pos == sizeof(path)-1 || path[pos] != 0) continue;
            const char *last = strrchr(path, '/');
            if (last && strcmp(last + 1, "UnityFramework") == 0) { base = images[i].load; break; }
        }
    }
    free(images); return base;
}
static NSString *ImageUUID(mach_port_t task, uint64_t base) {
    struct mach_header_64 h = {0};
    if (!ReadBytes(task, base, &h, sizeof(h)) || h.magic != MH_MAGIC_64 || h.ncmds > 4096 || h.sizeofcmds > 1024*1024) return nil;
    uint8_t *commands = malloc(h.sizeofcmds); if (!commands) return nil;
    NSString *result = nil;
    if (ReadBytes(task, base + sizeof(h), commands, h.sizeofcmds)) {
        size_t offset = 0;
        for (uint32_t i = 0; i < h.ncmds; i++) {
            if (offset + sizeof(struct load_command) > h.sizeofcmds) break;
            struct load_command *c = (struct load_command *)(commands + offset);
            if (c->cmdsize < sizeof(*c) || c->cmdsize > h.sizeofcmds-offset) break;
            if (c->cmd == LC_UUID && c->cmdsize >= sizeof(struct uuid_command)) {
                struct uuid_command *u = (struct uuid_command *)c;
                NSMutableString *s = [NSMutableString new];
                for (int j = 0; j < 16; j++) [s appendFormat:@"%02x", u->uuid[j]];
                result = s; break;
            }
            offset += c->cmdsize;
        }
    }
    free(commands); return result;
}
@implementation FFReader
- (NSDictionary *)inspect {
    NSMutableDictionary *report = [@{@"schema": @1, @"expectedVersion": @"2.132.1", @"timestamp": @([[NSDate date] timeIntervalSince1970]), @"featuresReady": @NO, @"mode": @"read-only"} mutableCopy];
    int error = 0; pid_t pid = GamePID(&error); report[@"pid"] = @(pid);
    if (!pid) { report[@"status"] = error ? @"Không đọc được danh sách tiến trình" : @"Chưa tìm thấy Free Fire MAX"; report[@"errno"] = @(error); return report; }
    mach_port_t task = MACH_PORT_NULL; kern_return_t kr = task_for_pid(mach_task_self(), pid, &task); report[@"taskResult"] = @(kr);
    if (kr != KERN_SUCCESS) { report[@"status"] = @"Không có quyền đọc tiến trình game"; return report; }
    @try {
        uint64_t base = UnityBase(task); report[@"unityBase"] = Hex(base);
        if (!base) { report[@"status"] = @"Chưa tìm thấy UnityFramework"; return report; }
        NSString *uuid = ImageUUID(task, base); report[@"unityUUID"] = uuid ?: @"";
        if (![uuid isEqualToString:@"d3f49d05bfb830ecaf6a032ba5657074"]) { report[@"status"] = @"Binary game khác bản đã phân tích"; return report; }
        const uint64_t additions[] = {0xbe93418, 0xb8, 0, 0x90};
        NSArray *keys = @[@"gameFacade", @"staticFields", @"currentGame", @"match"];
        uint64_t current = base;
        for (NSUInteger i = 0; i < 4; i++) {
            uint64_t address = current + additions[i], next = 0;
            if (address < current || !ReadBytes(task, address, &next, sizeof(next))) { report[@"status"] = @"Lần đọc thất bại; cần kết nối lại"; report[@"failedStage"] = keys[i]; return report; }
            report[keys[i]] = Hex(next);
            if (!Pointer(next)) { report[@"status"] = i == 0 ? @"Game chưa khởi tạo lớp" : @"Chưa có dữ liệu trận đấu hợp lệ"; report[@"waitingStage"] = keys[i]; return report; }
            current = next;
        }
        report[@"status"] = @"Có con trỏ trận đấu; chưa xác minh camera/người chơi";
    } @finally { mach_port_deallocate(mach_task_self(), task); }
    return report;
}
@end
