# SCUM Server Automation — Docker Compose

Chạy SCUM Server Automation (SSA) 6.2.0 dưới WineHQ, do SSA quản lý SCUM Dedicated Server. Đây là server manager, không phải launcher cho người chơi. Image tải bản portable chính thức và xác minh SHA-256. SSA, game và Wine dùng cùng một prefix; không cài native crypt32.

## Yêu cầu

- Linux x86_64, Docker Compose; tối thiểu 16 GB RAM dành cho container, còn đủ bộ nhớ cho hệ điều hành và các dịch vụ khác. Game trống có thể dùng khoảng 10 GB.
- Ít nhất 30 GB ổ trống cho server (~20 GB), prefix, update và backup; nên dự phòng nhiều hơn.
- Host `vm.max_map_count >= 1048576`: kiểm tra `sysctl vm.max_map_count`. Đặt tạm bằng `sudo sysctl -w vm.max_map_count=1048576`; cấu hình sysctl trên host để giữ sau reboot.
- Đảm bảo port không bị dịch vụ khác chiếm trước khi chạy. Không tự ý đổi sysctl trên host đang chạy nhiều dịch vụ nếu chưa cân nhắc ảnh hưởng.

## Cài đặt

1. `cp .env.example .env` nếu chưa có `.env`; sửa `BIND_IP` thành IP thực trên host, hoặc `0.0.0.0`. Sửa các port nếu cần; `GAME_PORT_PLUS_1` và `GAME_PORT_PLUS_2` phải bằng game port +1 và +2. `WEB_PORT` là port phía host; panel trong container vẫn dùng 8080.
2. `docker compose build` rồi `docker compose up -d`.
3. Xem `docker compose logs -f scum-server`. Khi có URL setup token, mở qua SSH tunnel: `ssh -L 8080:127.0.0.1:8080 user@server`, sau đó dùng URL localhost từ log ở máy cá nhân. Thay port tunnel nếu đổi `WEB_PORT`. Token là bí mật, không chia sẻ log.
4. Trong wizard chọn thư mục game `Z:\\data\\server` (hoặc `/data/server`), backup trong `Z:\\data\\manager\\backups`, và port game/query khớp `.env`. Để SSA tự khởi động server, không bật `panelStartsServer`. Sau setup, trong Settings đặt `steamCmd` tới `/usr/games/steamcmd` hoặc `/usr/lib/games/steam/steamcmd/steamcmd.sh`; đặt `stopServerOnExit=true`. Các thiết lập game, tên server, giới hạn người chơi và update do SSA quản lý, không còn tự ghi từ biến môi trường của dự án cũ.
5. Chạy Save & Install trong wizard. Theo dõi install, game log và xác minh client kết nối. SteamCMD có thể tải hàng chục GB; không xóa hoặc ghi đè `data/server/SCUM/Saved` khi nâng cấp server cũ.

Panel mặc định chỉ bind 127.0.0.1; tránh mở công khai khi chưa cấu hình HTTPS và bảo vệ truy cập. Các game port mặc định: 7777, 7778, 7779 và 27015 UDP; 7779 TCP là cổng kết nối game, không được coi là RCON đã xác thực. Không public cổng nội bộ SSA Bridge. Nếu đổi port trong wizard, phải sửa mapping Compose cho khớp và tạo lại container.

SSA luôn in `localhost:8080` khi panel của nó lắng nghe trên port 8080 bên trong container. Đây không phải port phía host. Ví dụ `WEB_PORT=9090` tạo ánh xạ host 9090 → container 8080: giữ nguyên `/admin/?setup_token=...` trong log nhưng thay `localhost:8080` bằng địa chỉ host và port 9090 khi mở từ máy khác. Nếu dùng SSH tunnel `ssh -L 9090:127.0.0.1:9090 user@server`, mở `http://localhost:9090/admin/?setup_token=...` trên máy cá nhân. Sau khi đổi `WEB_PORT` trong `.env`, chạy `docker compose up -d` để tạo lại container; chỉ `restart` không cập nhật port mapping. Nếu đổi cả `web.port` bên trong SSA thì phải đổi port container trong Compose tương ứng.

## Dữ liệu và dừng an toàn

`data/manager/` chứa executable, config, data và backups; `data/server/` chứa game và save; `data/wine/` chứa prefix và licence bridge. Không xóa prefix hoặc dữ liệu khi cập nhật. HOME của SteamCMD nằm trong `data/home/`; trước khi dùng cần kiểm tra đường dẫn/khả năng cập nhật từ wizard. `data/steamcmd/` dành cho bản SteamCMD tùy chọn cài riêng.

`docker compose stop` gửi SIGINT qua tini tới SSA, với thời gian chờ mặc định 10 phút. Đặt `STOP_GRACE_PERIOD` lớn hơn `3 * stopTimeoutSeconds + 30` giây. Đã kiểm tra shutdown manager trống; chưa kiểm tra save thực tế của game đang chạy. Khi cần backup thủ công, stop server rồi sao lưu toàn bộ `SCUM/Saved` và database.

SSA không tự thay executable khi chạy dưới Wine. Để cập nhật manager, dừng container, tải và xác minh release chính thức rồi thay `data/manager/SCUM-Server-Automation.exe`; rebuild image không ghi đè bản đã tồn tại. Luôn backup trước.

Tài liệu: https://scumsa.com/docs/owners/hosting-wine
