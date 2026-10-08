# ESP tích hợp — bản thử nghiệm đầu tiên

Bản cài: build/FreeFireMAX-2.132.1-ESP-TEST.ipa. Đây là IPA game có menu tích hợp; không phải ứng dụng HUD riêng. Bundle ID vẫn là com.dts.freefiremax; bản này có thể thay game cùng ID đang cài. Chưa thử cài bằng TrollStore hay chạy trên iPhone. Không khẳng định ESP hoạt động chỉ từ kết quả build.

Mở bằng TrollStore để cài. UnityFramework bị thêm LC_LOAD_DYLIB nên chữ ký cũ không còn khớp; TrollStore phải ký lại binary khi cài. Không dùng bản này để cài trực tiếp qua App Store.

Mở game, vào trận. Nút ESP đang tắt xuất hiện ở góc màn hình sau khi game hoạt động; chạm để bật. Phần vẽ hiển thị khung đầu–chân và tên nhân vật từ API Unity; lọc người chơi cục bộ, đồng đội và người đã chết qua các getter game. Chưa có aim. ESP mặc định tắt mỗi lần chạy game. Vùng vẽ không nhận thao tác; chỉ nút ESP/Log nhận chạm.

Nếu chưa có khung, xem dòng trạng thái: đợi IL2CPP, đợi trận, chưa có camera, chưa nhận diện danh sách, hoặc số nhân vật đã đọc. Chọn Log để chia sẻ FFESP.log. Log hiện lưu trạng thái gần nhất, số danh sách/nhân vật/transform/phép chiếu, kích thước màn hình; không ghi tên người chơi.

Bộ đọc dùng il2cpp_runtime_invoke với GameFacade.CurrentMatch, Camera.get_main (fallback camera đang hoạt động trong CurrentCameraControllerManager), Transform.get_position, Camera.WorldToScreenPoint, Player.get_HeadBoneTransform, get_RootTransform, get_NickName. Dictionary được nhận diện từ kiểu trường COW.GamePlay.Player và vị trí trường value/stride lấy qua API IL2CPP. Không dùng địa chỉ hàm cố định, không liên lạc máy chủ key.

Kiểm tra: 8 tình huống phép tính khung trên portrait/landscape, điểm phía sau camera, tọa độ NaN, chiều cao đảo, kích thước 0, ngoài màn hình, khung cắt biên đều đạt trên runner. Dylib đã compile arm64 iOS16 và ký ad hoc. Gói IPA đã kiểm tra ZIP CRC; chỉ UnityFramework và Info.plist của game được sửa, thêm FFMAXESP.dylib; tất cả thành viên gốc khác có hash giống IPA đầu vào. Chữ ký UnityFramework phải được ký lại khi cài; không coi việc kiểm tra cấu trúc gói là xác minh cài/chạy thành công.

Build nguồn bằng bash build-esp-macos.sh hoặc workflow Build integrated ESP. Thư viện được build trên GitHub; IPA game được ghép tại Windows, không tải IPA game lên repository. Script ghép: C:/Users/Admin/Downloads/FFMAX-analysis/package-integrated-esp.py. Hồ sơ UUID đầu vào d3f49d05bfb830ecaf6a032ba5657074.
