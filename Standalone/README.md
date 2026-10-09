# TIPA riêng — nền tảng chưa hoàn chỉnh 0.2.0

**Không có ESP và chưa có lớp phủ trên game.** Đây là phần có thể hoàn thiện, kiểm tra và tái lập của dự án, không thay thế mục tiêu ESP bằng menu tiện ích. Hai trạng thái ESP/HUD luôn khóa, không có dữ liệu đối thủ giả. Không yêu cầu chạy game hoặc đăng nhập.

## Phạm vi bản build này

Build chỉ biên dịch `main.m` và `State.m` trong thư mục này. Không biên dịch `Sources/FFReader.m`, `ESP/*` hoặc dùng các script sửa IPA game. Các mô-đun cũ vẫn tồn tại trong repo để đối chiếu lịch sử, **không thuộc gói mới**.

- Giao diện UIKit, chữ theo Dynamic Type, màu hệ thống, công tắc tính năng không hỗ trợ bị vô hiệu hóa.
- Bật/tắt ghi log trong phiên; lưu lựa chọn bằng NSUserDefaults. Không lưu các sự kiện giữa các phiên.
- Log chỉ nhận 5 mã sự kiện cố định, tối đa 32 mục. Không lấy PID, tên thiết bị, ID tài khoản, màn hình, địa chỉ bộ nhớ, phiên bản game hay token.
- Xem JSON trước khi xuất; xuất bản chụp tĩnh qua bảng chia sẻ do người dùng chọn. Xóa tệp cache khi bảng chia sẻ hoàn tất. Tắt log xóa sự kiện trong RAM; không xóa các bản bạn đã chia sẻ ra ngoài.
- Không module aim, đọc/ghi bộ nhớ ngoài tiến trình, chèn dylib, request mạng, DNS, helper root hoặc private overlay. Không khai báo entitlement đặc biệt.

## Build tái lập

Trên macOS có Xcode/iOS SDK và Python 3:

```sh
bash Standalone/build.sh
bash Standalone/simulator.sh
```

Hoặc chạy workflow **Build standalone foundation (ESP blocked)**. Artifact **HUD-Foundation-not-ESP** chứa TIPA, kết quả kiểm thử, xác minh gói và ảnh simulator. `build.sh` chạy kiểm thử logic Foundation trên macOS, build iOS arm64 min 16.0, ký ad hoc, xác minh chữ ký, ZIP, bundle ID, entitlement và import. TIPA không phải bản phân phối App Store; TrollStore ký lại khi cài.

Script simulator dùng iPhone/iOS runtime có sẵn trên runner và lưu danh sách runtime. Không coi đó là thiết bị iOS 16.6 hay bằng chứng lớp phủ ngoài ứng dụng. Ảnh chụp chỉ kiểm tra màn hình chính sáng/tối, không xác minh mọi tương tác.

## Cài và gỡ (thiết bị chưa kiểm chứng)

1. Tải `FFMAX-HUD-Foundation-0.2.0.tipa`, mở bằng TrollStore và cài. Bundle ID `vn.local.ffmaxhud.foundation`, khác game và HUD cũ.
2. Mở **HUD Foundation**. Màn hình phải nói rõ chưa hoàn chỉnh; ESP/HUD phải khóa. Bạn không cần mở Free Fire.
3. Có thể xem báo cáo, bật ghi log, đóng/mở lại ứng dụng và kiểm tra lựa chọn được giữ. Đây là quy trình kiểm tra tùy chọn, chưa được ghi là đã đạt trên thiết bị.
4. Gỡ qua mục Apps của TrollStore. Gói này không cài profile, daemon hay helper, không có bước gỡ thành phần trong game. Các tệp JSON đã chia sẻ ra Files cần xóa tại nơi đã lưu nếu muốn.
5. Việc gỡ bản này không gỡ bản ESP cũ, DNS cũ hoặc án khóa tài khoản.

Theo [TrollStore](https://github.com/opa334/TrollStore), iOS 16.6 nằm trong khoảng phiên bản hỗ trợ và ứng dụng được gỡ từ TrollStore. Điều đó không xác nhận riêng gói này đã cài/chạy trên điện thoại của bạn.

## Điểm chặn ESP

Cần nguồn do game/nhà cung cấp cho phép truy cập từ ứng dụng riêng, cung cấp vị trí thế giới hoặc các điểm xương, trạng thái người chơi/đội, camera view-projection, viewport/orientation, quy ước tọa độ và thời điểm của từng frame. Chưa có API/IPC/telemetry được hỗ trợ như vậy trong các tệp cung cấp. IPA giải mã có mã và metadata; nó không cung cấp luồng dữ liệu được hỗ trợ từ game chính thức đang chạy.

Các getter IL2CPP của bản tích hợp chỉ dùng trong tiến trình game. Bộ đọc task port cũ dùng quyền đặc biệt và chưa xác minh toàn bộ chuỗi dữ liệu; không chuyển nó vào target mới rồi gọi là nguồn được hỗ trợ. Đọc ảnh màn hình cũng không cung cấp vị trí/camera chính xác của đối thủ bị che khuất.

**Kết luận: ESP chưa khả thi theo nguồn dữ liệu và bằng chứng hiện có.** Phần thiếu là nguồn dữ liệu được hỗ trợ nêu trên; không phải chỉ thêm SDK hoặc đổi đuôi IPA thành TIPA. Không cần thêm log của tài khoản bị khóa để kết luận giới hạn này.

## Điểm chặn lớp phủ

Mã tham khảo TrollSpeed có tiến trình quyền root và gọi API riêng `SBSAccessibilityWindowHostingController` để đăng ký context. Xem [mã tham khảo](https://github.com/Lessica/TrollSpeed). Đây là một hướng kỹ thuật có tồn tại, không phải xác minh khả năng hoạt động của project trên máy người dùng. Chúng ta chưa có kết nối điều khiển/kiểm thử tới iPhone iOS 16.6; không bật công tắc lớp phủ bằng suy đoán.

Target hiện tại chỉ tạo UIWindow trong chính ứng dụng, không triển khai lớp phủ toàn hệ thống. Thiết bị thực là cần thiết để xác minh một backend lớp phủ sau này, có thể dùng Home/Settings để kiểm tra, không cần tài khoản game. [Apple mô tả](https://support.apple.com/guide/security/security-of-runtime-process-sec15bfe098e/web) ứng dụng bên thứ ba được sandbox và truy cập dữ liệu ngoài ứng dụng qua dịch vụ được hệ thống cung cấp.

## Kiểm chứng và phân tích

Xem `ASSESSMENT.md`, `evidence/original-audit.json`, `evidence/input-inventory.json` và `VALIDATION.md`. Tái phân tích gói gốc bằng:

```sh
python3 Standalone/audit-original.py /path/to/FFMAX+DNS.tipa /path/to/audit.json
```

Script chỉ đọc ZIP/Mach-O/plist; không chạy gói gốc hoặc gọi DNS. Kiểm tra import không phải chứng minh đầy đủ không có hành vi khác; với target mới, cần xem cả source allowlist, thư viện liên kết và nội dung gói.
