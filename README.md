# FFMAX New HUD — mã nguồn giai đoạn 1

Menu UIKit mới, không dùng binary HUD cũ và không có bước nhập key.

Có: kiểm tra tiến trình FreeFireMAX, task_for_pid, liệt kê ảnh dyld, kiểm tra UUID UnityFramework đúng IPA đã cung cấp, đọc chuỗi GameFacade → static_fields → CurrentGame → m_Match, báo lỗi từng bước, xuất báo cáo JSON. Tất cả đọc bộ nhớ, không ghi vào game. Các phép đọc được chạy ngoài luồng giao diện. Task port được giải phóng sau mỗi kiểm tra; không giữ con trỏ giữa các lần kiểm tra.

Chưa có: lớp phủ xuất hiện trên game, ESP, aim, danh sách người chơi và phép chiếu tọa độ camera. Hai công tắc Aim/ESP bị vô hiệu hóa và ghi rõ chưa triển khai. Đây là mã nguồn ứng dụng menu/chẩn đoán; không phải bản đầy đủ chức năng. Con trỏ m_Match được kiểm tra hình thức và kết quả đọc, chưa chứng minh ngữ nghĩa đối tượng trên thiết bị.

## Build

Cần macOS + Xcode có iOS SDK. Không cần Theos. Mở Terminal trong thư mục này và chạy:

```sh
bash build-macos.sh
```

Script dùng xcrun clang, tạo app arm64 iOS 16.0+, ký bằng ldid nếu có hoặc codesign ad hoc, đóng gói build/FFMAX-NewHUD.tipa. Cài gói bằng TrollStore. Không có chứng chỉ App Store. Chưa thử ký/cài trên iPhone; entitlement thực tế phụ thuộc môi trường TrollStore. Tham khảo công cụ build chính thức: https://developer.apple.com/documentation/xcode ; TrollStore: https://github.com/opa334/TrollStore .

Ứng dụng riêng có bundle ID vn.local.ffmaxnewhud nên không ghi đè game hay HUD cũ. Tính năng chia sẻ file Documents được bật.

## Hồ sơ game

IPA xuất từ thiết bị: com.dts.freefiremax, phiên bản 2.132.1, build 2019118522. UUID UnityFramework d3f49d05bfb830ecaf6a032ba5657074. RVA GameFacade 0xBE93418, class.static_fields 0xB8, static CurrentGame 0, MatchGame.m_Match 0x90. Nguồn đối chiếu: game-ipa/facade-methods.txt và metadata trong thư mục FFMAX-analysis; log V9/V10 xác nhận các bước đọc. Nếu UUID khác, chương trình từ chối dùng cấu hình này.

## Kiểm tra

Máy tạo mã nguồn chạy Windows, không có Xcode/iOS SDK/compiler iOS. Chưa compile native, chưa thử trên iPhone, chưa có IPA/TIPA mới. Các kiểm tra hiện tại chỉ gồm cấu trúc plist, cú pháp shell và cấu trúc gói nguồn. Xem VALIDATION.json. Không coi các kiểm tra đó là bằng chứng app chạy được.

## Không có Mac: build bằng GitHub Actions

Có sẵn .github/workflows/build.yml. Tạo một repository GitHub của bạn, đưa toàn bộ nội dung thư mục này lên (bao gồm thư mục .github). Mở Actions → Build iOS menu → Run workflow. Khi workflow thành công, tải artifact FFMAX-NewHUD, giải nén để lấy FFMAX-NewHUD.tipa rồi cài bằng TrollStore. Workflow dùng máy macOS của GitHub; không cần Mac cá nhân. Cần tài khoản GitHub và Actions được bật. Việc build từ xa chưa được thực hiện trong phiên này và có thể cần sửa lỗi compile phát sinh.

Hướng dẫn chính thức: https://docs.github.com/en/actions/managing-workflow-runs/manually-running-a-workflow và https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts . Chưa có tài khoản/repository được kết nối để chạy workflow tự động.
