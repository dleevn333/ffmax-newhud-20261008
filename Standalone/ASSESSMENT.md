# Kiểm tra từ tệp thật — 09/10/2026

## Kiểm kê và hướng dẫn

`C:/Users/Admin/Desktop/game` không tồn tại. Project thực: `C:/Users/Admin/Downloads/FFMAX-NewHUD`; phân tích cũ: `C:/Users/Admin/Downloads/FFMAX-analysis`. Đã tìm AGENTS.md ở project và các thư mục cha tới C:/; không có tệp nào. Đã đọc README, workflow, build scripts, mã ứng dụng, ESP và hướng dẫn UI/UX đã công bố trong phiên này.

TIPA gốc có thực tại `Downloads/Telegram Desktop/FFMAX+DNS.tipa`; IPA game có thực tại `Downloads/com.dts.freefiremax_2.132.1_decrypted.ipa`. Hash/kích thước và các log thực sự tìm thấy được ghi trong `evidence/input-inventory.json`. Không dựa vào tệp chỉ được nhắc trong cuộc trò chuyện khác. Không cần bổ sung tệp để hoàn thành phân tích khả thi này.

## Bằng chứng và giới hạn

Script mới tự đọc load commands, symbol table, indirect symbol table, import stubs, lệnh ARM64 BL và entitlement trong chữ ký từ ZIP gốc; không dựa vào danh sách import JSON cũ. ZIP có 14 thành viên không phải thư mục, CRC đạt. SHA256 gói: `0e0a540f352c6dfb234213fae6d93fec2929ddc0a8e952384f2d90652ab2cbbc`.

| Thành phần | Gói gốc / bằng chứng | Điều chưa chứng minh |
| --- | --- | --- |
| Giao diện | Có executable apple, Info.plist, icon, localization và UIKit trong LC_LOAD_DYLIB; ảnh người dùng từng cung cấp cho thấy màn hình bật HUD/key/DNS | Không khôi phục được toàn bộ mã nguồn; asset và thư viện không chứng minh từng tính năng chạy |
| Lớp phủ | Gói liên kết SpringBoardServices/BackBoardServices/GraphicsServices, có entitlement window hosting và selector `_contextId` | Chưa xác định đầy đủ đường đăng ký global window trong binary bị làm rối; không suy ra đang gọi chỉ từ tên/selector. Mã TrollSpeed tham khảo không chứng minh gói gốc giống hệt |
| Đọc dữ liệu | Sáu direct BL tới API đọc bộ nhớ; ví dụ 0x100df53b8 → stub `_vm_read_overwrite` 0x101da0d28. BL tại 0x100df2128 → `_task_for_pid` | Không biết đối số/process đích chỉ từ callsite. Báo cáo/log V10 cũ hỗ trợ việc đọc một phần chuỗi nhưng chưa chứng minh player/camera |
| Ghi bộ nhớ | BL tại 0x100df4cc8 → `_vm_write` 0x101da0d34, xác minh instruction và indirect symbol từ gói | Không chứng minh đường này đã chạy, ghi vào game hay gây ban; không đồng nhất lệnh tồn tại với hành vi thiết bị |
| Chèn thư viện | Trong project tích hợp, `package-esp.py` thêm LC_LOAD_DYLIB vào UnityFramework; `ESP/UnityBridge.m` dùng dlsym/runtime_invoke trong game | Với TIPA gốc, chưa kết luận có/không injection chỉ từ import. Có giải tên động và obfuscation nên chưa thể xác minh toàn bộ |
| Mạng | Selector `dataTaskWithRequest:completionHandler:` tồn tại; DNS profile có endpoint HTTPS cụ thể | Selector không chứng minh request đã gửi, payload, host xác thực thực tế hoặc dữ liệu nào bị truyền. Chưa bắt traffic/chạy gói gốc |
| DNS | Parse plist thật: payload `com.apple.dnsSettings.managed`, DNSProtocol HTTPS, endpoint NextDNS. Chi tiết trong JSON audit | Không có rule phía dịch vụ trong gói, không chứng minh lọc gì hoặc anti-ban; chưa chứng minh profile được cài trên thiết bị |
| Quyền | Đọc trực tiếp XML entitlement của chữ ký: 69 mục, gồm task ports, no-sandbox, persona và platform-application | Khai báo không đồng nghĩa quyền được cấp hoặc dùng. Số lượng quyền không đủ kết luận mã độc |

59 điểm gọi trực tiếp thuộc nhóm API được chọn được lưu trong audit; đây không phải 59 hành vi độc hại. Không chạy binary không rõ mục đích, không liên hệ endpoint DNS/key, không thay profile thiết bị.

## Kiến trúc đã thực hiện

Target `Standalone` mới: UIKit → HUDState → NSUserDefaults / báo cáo JSON có schema đóng. Không có data-provider game và không có backend overlay; trạng thái luôn bị chặn/chưa triển khai. Build chỉ lấy hai tệp .m mới. Không cấp entitlement riêng, không mạng/DNS, root helper, memory API, injection, aim, code né chống gian lận hoặc vượt khóa.

Mã cũ lưu trong repo để kiểm toán; không đưa vào gói mới. Không sửa/xóa IPA gốc, game hoặc gói TIPA gốc. Không phát hành target mới như ESP hoàn chỉnh. Giới hạn nguồn dữ liệu và thiết bị được nêu trong README.
