# Báo cáo kiểm chứng — 09/10/2026

## Kết quả đã có

- Kiểm kê tệp thật và hash: `evidence/input-inventory.json`. TIPA gốc và IPA game được băm lại sau khi làm việc, vẫn trùng trước khi làm.
- Audit gói gốc: parse lại ZIP, Mach-O, import, lệnh BL và entitlement trực tiếp; `evidence/original-audit.json`. Không thực thi binary gốc. Có giới hạn phân tích tĩnh đã ghi trong ASSESSMENT.
- [Build đầu](https://github.com/dleevn333/ffmax-newhud-20261008/actions/runs/37884765742), source commit `8794490`: thành công trên macOS runner. Foundation tests đã chạy thật, không chỉ compile.
- Các kiểm thử: ESP/HUD không thể bật qua preference cũ; lưu/đọc lại lựa chọn log; giá trị cấu hình sai kiểu; từ chối log tự do chứa token giả trong test; giới hạn 32 mục; xóa log/tắt ghi; snapshot xuất không thay đổi theo log trong RAM; lỗi ghi tệp trả NSError.
- Build iOS arm64 min 16.0 thành công, codesign ad hoc và `codesign --verify --strict` đạt trên runner. Xác minh gói lần nữa trên Windows: CRC, bundle ID riêng, chỉ các thành viên được cho phép, không entitlement đặc biệt, chỉ liên kết UIKit/Foundation/CoreFoundation/libobjc/libSystem, không import các API can thiệp/mạng trong danh sách kiểm tra. Kiểm tra import là một lớp kiểm tra bổ sung cho việc review source/build allowlist, không phải chứng minh hành vi đầy đủ.

## Simulator

Lần chạy bổ sung [37884918823](https://github.com/dleevn333/ffmax-newhud-20261008/actions/runs/37884918823), source commit `8c93144`: **thành công**. Cài và mở ứng dụng trên **iPhone 16 Pro Simulator / iOS 18.6**, chụp hai ảnh sáng/tối, kết thúc tiến trình và gỡ app đều hoàn tất. Đã xem hai ảnh: màn hình chính hiện đúng trạng thái chưa hoàn chỉnh, hai tính năng khóa, chữ không bị cắt ở kích thước đã thử. Ảnh nằm tại `evidence/simulator-light.png` và `evidence/simulator-dark.png`.

Chưa tự động thao tác bảng chia sẻ hoặc kiểm tra VoiceOver/Dynamic Type lớn/landscape; không coi các phần đó đã đạt chỉ vì launch thành công. Không coi simulator là thiết bị người dùng.

Gói giao từ lần chạy này: SHA256 `059647a8d52c156a04e18b4939f5e87f05934c280ec5a0a3d00ecb42e532e388`; binary SHA256 `f310d495eb787011aa38d31c8261ab23a2a5475f937f0720f6766174511151e2`. Binary trùng lần build trước; hash ZIP khác do metadata đóng gói, không cam kết ZIP tái lập từng byte. Báo cáo máy đọc nằm tại `evidence/package-validation.json`.

## Chưa kiểm chứng / bị chặn

| Hạng mục | Trạng thái |
| --- | --- |
| Cài/ký lại bằng TrollStore trên iPhone iOS 16.6 của người dùng | Chưa kiểm tra |
| Giao diện, VoiceOver, bảng chia sẻ thực tế trên iOS 16.6 | Chưa kiểm tra |
| Lớp phủ trên Home/Settings/game | Chưa triển khai và chưa kiểm tra thiết bị |
| Vị trí/camera trực tiếp từ Free Fire MAX | Không có nguồn dữ liệu được hỗ trợ đã xác minh |
| ESP hoạt động | Bị chặn; không có dữ liệu giả hoặc bản demo được gọi là ESP |
| Tránh khóa tài khoản | Không xây dựng, không kiểm chứng, không tuyên bố |

Máy Windows không có `xcrun`, `xcodebuild`, compiler iOS hoặc `idevice_id` trong PATH. SDK và ký ad hoc được xử lý bằng runner macOS, nên không còn là trở ngại build. Không có kênh điều khiển/kiểm thử tới iPhone trong phiên làm việc; không suy ra từ đó điện thoại có/không cắm USB. Không yêu cầu người dùng vào trận hoặc dùng tài khoản thật.

Ứng dụng được giao là phần nền tảng chưa hoàn chỉnh. Chức năng ứng dụng (state/config/export) được kiểm thử ở mức nêu trên; không công bố rằng ESP hoặc lớp phủ đã hoạt động.
