# Docker Template

Tomcat (+Relay), Nginx(SSL), MariaDB를 한 번에 띄우는 Compose 스택입니다. **모든 설정은 `.env` 한 곳**에서 관리

---

## 요구 사항

| 항목             | 최소 버전 | 비고                                        |
| -------------- | ----- | ----------------------------------------- |
| Docker         | 20.10 | Windows 11/10 + WSL2 또는 Docker Desktop 권장 |
| Docker Compose | v2.20 | `docker compose` CLI 사용                   |

---

## 디렉터리 구조

```
project-root/
├── docker-compose.yml      # 서비스 정의
├── Dockerfile              # Tomcat/Relay 베이스 이미지
├── entrypoint.sh           # 컨테이너 부트 스트랩
├── .env.example            # 복사해 .env 작성
├── nginx/
│   └── certs/
│   │   └── fullchain.pem
│   │   └── privkey.pem
│   └── templates/
│       └── proxy.template  # envsubst 전용 템플릿
└── .gitignore              # .env
```

---

## 빠른 시작

```powershell
# PowerShell 예시
> git clone https://github.com/seunghwan94/docker-template .

# 환경 변수 파일 준비
> copy .env.example .env
> notepad .env         # 포트·도메인·비밀번호 수정

# 최초 빌드 (버전·빌드 ARG 바꾼 경우에만 필요)
> docker compose build

# 서비스 실행 / 재배포
> docker compose up -d

# 로그 확인
> docker compose logs -f
```

* **런타임 변수만 바꾸면**: `.env` 수정 → `docker compose up -d`
* **버전(빌드 ARG) 바꾸면**: `.env` 수정 → `docker compose build` → `docker compose up -d`

---

## 주요 환경 변수 (`.env`)

| 키                                                         | 설명                                                                                                                                                                                                                                       | 예시               |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| `PROJECT`                                                 | 컨테이너 접두사                                                                                                                                                                                                                                 | `myproject`      |
| `TZ`                                                      | 타임존(ENTRYPOINT 방식)                                                                                                                                                                                                                       | `Asia/Seoul`     |
| `UBUNTU_VERSION`                                          | 베이스 OS                                                                                                                                                                                                                                   | `22.04`          |
| `JAVA_PACKAGE`                                            | JDK 패키지                                                                                                                                                                                                                                  | `openjdk-17-jdk` |
| `TOMCAT_MAJOR / TOMCAT_VERSION`                           | Tomcat 버전                                                                                                                                                                                                                                | `9` / `9.0.105`  |
| `NGINX_VERSION`                                           | Nginx 이미지 태그                                                                                                                                                                                                                             | `1.25`           |
| `MARIADB_VERSION`                                         | MariaDB 이미지 태그                                                                                                                                                                                                                           | `10.6`           |
| `TOMCAT_*_PORT`                                           | 호스트↔컨테이너 포트                                                                                                                                                                                                                              | `8080`, `8443` 등 |
| `RELAY_*_PORT`                                            | Relay 포트                                                                                                                                                                                                                                 |                  |
| `NGINX_*_PORT`                                            | Nginx 퍼블릭 포트                                                                                                                                                                                                                             | `80`, `443`      |
| `ROOT_PASSWORD`                                           | Tomcat/Relay 내부 root 비밀번호                                                                                                                                                                                                                | *비밀*             |
| `KEYSTORE_ALIAS` / `KEYSTORE_PASSWORD` / `KEYSTORE_DNAME` | Tomcat SSL용 **Java KeyStore**(JKS) 생성에 쓰이는 값.<br>  • **KEYSTORE\_PASSWORD**: storepass · keypass (6자 이상 필수)<br>  • **KEYSTORE\_ALIAS**: 인증서 별칭(기본 `tomcat`)<br>  • **KEYSTORE\_DNAME**: 인증서 subject DN(ex. `CN=example.com,OU=Dev, ...`) |                  |
| `DB_*`                                                    | MariaDB 비밀번호·포트                                                                                                                                                                                                                          |                  |
| `SITE_HOST`                                               | 외부 도메인                                                                                                                                                                                                                                   | `example.com`    |
| `UPSTREAM_TOMCAT/RELAY`                                   | Nginx 업스트림                                                                                                                                                                                                                               | `tomcat:8080`    |

> `.env` 는 절대 VCS에 커밋하지 마세요. 대신 `.env.example`만 공유합니다.

---

## TLS / SSL 인증서 (Nginx)

Nginx 설정(`proxy.template`)에 

```nginx
ssl_certificate     /etc/nginx/certs/fullchain.pem;
ssl_certificate_key /etc/nginx/certs/privkey.pem;
```

가 포함돼 있습니다. **`nginx/certs/` 폴더에 두 PEM 파일을 준비**해야 443 포트가 정상 작동합니다.

### Windows에서 자체 서명 인증서 만드는 방법

아래 예시는 **Git for Windows**(Git Bash) 또는 **WSL2** 환경이 있는 Windows 10/11에서 OpenSSL로 PEM 파일을 만드는 쉬운 방법입니다.

1. **OpenSSL 설치 확인**
   Git Bash를 열어 `openssl version` 으로 버전을 확인합니다. 없으면 Git for Windows ([https://gitforwindows.org](https://gitforwindows.org)) 를 설치하거나 Chocolatey 로 `choco install openssl`.

2. **PEM 생성**

   ```bash
   # Git Bash 또는 WSL2 터미널
   mkdir -p nginx/certs && cd nginx/certs

   # 365일 유효, RSA 2048bit 키·인증서 생성
   openssl req -x509 -nodes -days 365 ^
     -newkey rsa:2048 -keyout privkey.pem -out fullchain.pem ^
     -subj "/C=KR/ST=Seoul/L=Seoul/O=MyCompany/OU=Dev/CN=%SITE_HOST%"
   ```

   * `%SITE_HOST%` 대신 사용하는 도메인을 입력하거나 CMD/Powershell에서는 직접 문자열로 입력하세요.
   * 브라우저는 경고를 표시하지만 내부 테스트·스테이징 용도로 충분합니다.

3. **컨테이너 재시작**

   ```powershell
   > docker compose up -d nginx
   ```

### 운영환경: Let's Encrypt

Windows에서도 [win-acme](https://www.win-acme.com/) 같은 ACME 클라이언트를 사용해 인증서를 발급할 수 있습니다.

```powershell
# win-acme CLI 설치 후 예시
> wacs.exe --target manual --host example.com --installation none --validation http-01

# 발급된 fullchain.pem / privkey.pem 복사
> copy C:\certs\example.com\fullchain.pem nginx\certs
> copy C:\certs\example.com\privkey.pem  nginx\certs

> docker compose up -d nginx
```

자동 갱신은 win-acme가 Windows 작업 스케줄러에 등록해 줍니다.

> 인증서가 없으면 443 요청 시 Nginx가 즉시 종료됩니다. 개발 단계에서 HTTPS가 필요 없으면 `docker-compose.yml` 에서 443 포트 매핑과 certs 볼륨을 주석 처리하고 HTTP만 사용하세요.

---

## 버전 업데이트

1. `.env` 에서 `TOMCAT_VERSION`, `NGINX_VERSION`, `MARIADB_VERSION`, `UBUNTU_VERSION` 등을 수정.
2. 재빌드·재배포:

   ```powershell
   > docker compose build
   > docker compose up -d
   ```

---

## 데이터 & 백업

* DB 데이터는 **이름 있는 볼륨 `db_data`** 에 저장됩니다. Windows Docker Desktop에서는 `\\wsl$\docker-desktop-data\...` 경로로 확인 가능합니다.
* Tomcat 로그를 영속화하려면 예시처럼 볼륨을 추가합니다.

```yaml
services:
  tomcat:
    volumes:
      - tomcat_logs:/opt/tomcat/logs
volumes:
  tomcat_logs:
```

---

## 자주 쓰는 명령어 (PowerShell)

| 목적               | 명령                                |
| ---------------- | --------------------------------- |
| 전체 스택 중지         | `docker compose down`             |
| 이미지 재빌드(단일)      | `docker compose build tomcat`     |
| Tomcat 로그 실시간 보기 | `docker compose logs -f tomcat`   |
| 컨테이너 셸 접속        | `docker compose exec tomcat bash` |

---

> make Mago
