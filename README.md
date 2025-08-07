# 📬 Postfix SMTP 릴레이 설정 스크립트

이 스크립트는 **Postfix** 메일 서버를 외부 SMTP 서버(예: HiWorks, Gmail 등)를 통해 메일 릴레이할 수 있도록 설정합니다.  
TLS 암호화, SASL 인증, 인증서 생성 등 복잡한 과정을 자동화해 줍니다.

---

## 📝 사용법

```bash
./setup_postfix.sh '이메일' '비밀번호' 'SMTP도메인' '포트번호' '도메인'


---
## 🔧 사용 예시

복사해서 그대로 사용하세요 👇

```bash
./setup_postfix.sh 'admin@cudo.co.kr' '1111' 'smtps.hiworks.com' '465' 'pce.cudo.co.kr'
