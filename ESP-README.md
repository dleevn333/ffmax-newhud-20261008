# ESP tích hợp — bản thử nghiệm V2

Bản cài: build/FreeFireMAX-2.132.1-ESP-V2-TEST.ipa. Đây là IPA game có menu tích hợp; không phải ứng dụng HUD riêng. Bundle ID vẫn là com.dts.freefiremax; bản này có thể thay game cùng ID đang cài. Chưa thử cài bằng TrollStore hay chạy trên iPhone. Không khẳng định ESP hoạt động chỉ từ kết quả build.

Mở bằng TrollStore để cài. UnityFramework bị thêm LC_LOAD_DYLIB nên chữ ký cũ không còn khớp; TrollStore phải ký lại binary khi cài. Không dùng bản này để cài trực tiếp qua App Store.

Mở game, vào trận. Nút ESP đang tắt xuất hiện ở góc màn hình sau khi game hoạt động; chạm để bật. Phần vẽ hiển thị khung đầu–chân và tên nhân vật từ API Unity; lọc người chơi cục bộ, đồng đội và người đã chết qua các getter game. Chưa có aim. ESP mặc định tắt mỗi lần chạy game. Vùng vẽ không nhận thao tác; chỉ nút ESP/Log nhận chạm.

Nếu chưa có khung, xem dòng trạng thái: đợi IL2CPP, đợi trận, chưa có camera, chưa nhận diện danh sách, hoặc số nhân vật đã đọc. Chọn Log để chia sẻ FFESP.log. Log hiện lưu trạng thái gần nhất, số danh sách/nhân vật/transform/phép chiếu, kích thước màn hình; không ghi tên người chơi.

Bộ đọc dùng il2cpp_runtime_invoke với GameFacade.CurrentMatch, Camera.get_main (fallback camera đang hoạt động trong CurrentCameraControllerManager), Transform.get_position, Camera.WorldToScreenPoint, Player.get_HeadBoneTransform, get_RootTransform, get_NickName. Dictionary được nhận diện từ kiểu trường COW.GamePlay.Player và vị trí trường value/stride lấy qua API IL2CPP. Không dùng địa chỉ hàm cố định, không liên lạc máy chủ key.

Kiểm tra: 8 tình huống phép tính khung trên portrait/landscape, điểm phía sau camera, tọa độ NaN, chiều cao đảo, kích thước 0, ngoài màn hình, khung cắt biên đều đạt trên runner. Dylib đã compile arm64 iOS16 và ký ad hoc. Gói IPA đã kiểm tra ZIP CRC; chỉ UnityFramework và Info.plist của game được sửa, thêm FFMAXESP.dylib; tất cả thành viên gốc khác có hash giống IPA đầu vào. Chữ ký UnityFramework phải được ký lại khi cài; không coi việc kiểm tra cấu trúc gói là xác minh cài/chạy thành công.

Build nguồn bằng bash build-esp-macos.sh hoặc workflow Build integrated ESP. Hồ sơ UUID đầu vào d3f49d05bfb830ecaf6a032ba5657074.

Để workflow xuất IPA: vào Actions → Build integrated ESP → Run workflow, điền `ipa_url` bằng link HTTPS tải trực tiếp IPA đã giải mã phiên bản 2.132.1, rồi chạy. Tải artifact `FreeFireMAX-ESP-V2-IPA` và giải nén để lấy IPA. Nếu để trống URL, workflow chỉ xuất thư viện. URL hiện trong thông tin lần chạy; artifact trong repo public có thể được người khác tải. IPA gốc không được commit vào repo. Workflow kiểm tra UUID, ZIP CRC và hash các thành viên không sửa; artifact giữ 3 ngày. TrollStore cần ký lại khi cài.

Đóng gói tại máy có Python: `python package-esp.py --source original.ipa --library build/FFMAXESP.dylib --output build/FreeFireMAX-2.132.1-ESP-V2-TEST.ipa`.


## V2 — sửa bước tìm danh sách người chơi

Log bản đầu đã tới bước camera/kích thước màn hình nhưng collections=0, players=0. V2 duyệt trường của lớp hiện tại và lớp cha, nhận diện Dictionary theo lớp/kiểu trường rồi xác minh kiểu value là Player trước khi đọc phần tử. Bỏ điều kiện chuỗi tên Dictionary phải chứa tên Player. Chưa chứng minh điều kiện nào là nguyên nhân duy nhất trên iPhone; log V2 có matchHierarchy, fieldSamples, containerSamples, dictionaryFields, playerDictionaries để đối chiếu.

Kiểm thử hồi quy trên mã bộ đọc thực tế dùng API IL2CPP giả lập: trường danh sách trong lớp cha, tên generic không có tham số kiểu, danh sách không chứa Player (có giá trị giả không được đọc), bỏ trường static, loại nhân vật trùng. Tất cả đã đạt trên macOS; phép tính khung cũng đạt. Chưa xác nhận ESP V2 hoạt động trên thiết bị.

Nút Log xuất FFESP-V2.log, dùng bản chụp tĩnh để nội dung không thay đổi khi bảng chia sẻ mở. Được ghi từ trạng thái frame hiện tại; có thể không chứa lịch sử các frame trước.
