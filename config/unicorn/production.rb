upstream unicorn {
  server unix:/opt/k12ke/cap/main/shared/tmp/sockets/unicorn.sock;
}

server {
  listen 8080 default_server;
  server_name cap.k12ke.com;

  access_log /opt/k12ke/cap/main/log/access.log;
  error_log /opt/k12ke/cap/main/log/error.log;

  root /opt/k12ke/cap/;

  client_max_body_size 100m;
  error_page 404 /404.html;
  error_page 500 502 503 504 /500.html;
  try_files $uri/index.html $uri @unicorn;

  location @unicorn {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_pass http://unicorn;
  }
}
