# Java DevOps Demo

Yeh chhota Java web app GitHub Actions aur AWS EC2 par deployment seekhne ke liye hai. Isme Java 17, Spring Boot aur Maven use hue hain.

## App kya karta hai

- `GET /` par greeting aur app ka status dikhata hai.
- `GET /health` health status deta hai.
- `APP_MESSAGE` se greeting aur `PORT` se port badal sakte hain.
- `main` branch par push hone par GitHub Actions app build karke EC2 par deploy karta hai.

## Zaroori cheezein

- Local development ke liye Java 17 JDK aur Maven 3.6.3+
- AWS account aur Ubuntu 22.04 ya 24.04 EC2 instance
- GitHub account/repository; repository mein Actions enabled hon

### Windows par Java aur Maven install karein

PowerShell mein:

```powershell
winget install EclipseAdoptium.Temurin.17.JDK
winget install Apache.Maven
```

Install ke baad naya PowerShell khol kar check karein:

```powershell
java -version
mvn -version
```

Agar command na mile, terminal band karke dobara kholen.

## Apne computer par app chalayein

Project folder se PowerShell mein:

```powershell
mvn spring-boot:run
```

Browser mein <http://localhost:8080> kholen. Variables badal kar bhi chala sakte hain:

```powershell
$env:APP_MESSAGE = "Mere laptop se namaste!"
$env:PORT = "8081"
mvn spring-boot:run
```

Runnable JAR banane ke liye:

```powershell
mvn clean package
java -jar target/java-devops-demo.jar
```

## EC2 instance taiyar karein

AWS mein Ubuntu EC2 instance banayein. Security Group ke inbound rules:

1. SSH (TCP 22) ko **sirf apne IP address** se allow karein.
2. Demo website public karne ke liye Custom TCP (TCP 8080) ko `0.0.0.0/0` se allow karein. Production mein Nginx aur HTTPS istemal karein.

Apne computer se instance par connect karein:

```bash
ssh -i /path/to/your-key.pem ubuntu@EC2_PUBLIC_IP
```

Instance par Java install karke app user aur folder banayein:

```bash
sudo apt update
sudo apt install -y openjdk-17-jre-headless
sudo useradd --system --home /opt/java-demo --shell /usr/sbin/nologin java-demo
sudo install -d -o java-demo -g java-demo /opt/java-demo
```

App ke environment variables set karna optional hai. Defaults port `8080` aur `application.properties` mein di hui greeting hain. EC2 par:

```bash
sudo tee /etc/default/java-demo > /dev/null <<'EOF'
PORT=8080
APP_MESSAGE=Hello from my EC2 server!
EOF
sudo chmod 644 /etc/default/java-demo
```

Apne computer ke project folder se systemd service copy karke enable karein. Host aur key path apne values se badlein:

```bash
scp -i /path/to/your-key.pem deploy/java-demo.service ubuntu@EC2_PUBLIC_IP:/tmp/java-demo.service
ssh -i /path/to/your-key.pem ubuntu@EC2_PUBLIC_IP \
  'sudo install -m 644 /tmp/java-demo.service /etc/systemd/system/java-demo.service && sudo systemctl daemon-reload && sudo systemctl enable java-demo'
```

Pehle successful GitHub Actions deployment ke baad service start ho jayegi. EC2 par verify karein:

```bash
sudo systemctl status java-demo
curl http://localhost:8080/health
```

## GitHub repository mein code push karein

GitHub par ek **khali repository** banayein (README/license add na karein, kyunki project mein README pehle se hai). Apne computer ke project folder mein:

```powershell
git init
git add .
git commit -m "Add Java EC2 demo app"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_NAME/YOUR_REPOSITORY.git
git push -u origin main
```

`YOUR_GITHUB_NAME` aur `YOUR_REPOSITORY` ko apne GitHub username aur repository ke naam se badlein.

## GitHub Actions secrets set karein

GitHub repository mein **Settings → Secrets and variables → Actions → New repository secret** par jaakar yeh secrets banayein:

| Secret | Isme kya dalein |
| --- | --- |
| `EC2_HOST` | EC2 ka public IPv4 address ya public DNS |
| `EC2_USER` | Ubuntu EC2 ke liye `ubuntu` |
| `EC2_SSH_PRIVATE_KEY` | EC2 key pair ki private key ka poora content, BEGIN/END lines samet |
| `EC2_KNOWN_HOSTS` | EC2 host ki verified SSH host-key line |

`EC2_KNOWN_HOSTS` ke liye apne computer par yeh command chalayein, **lekin pehle trusted source se host-key fingerprint verify karein**:

```bash
ssh-keyscan -H EC2_PUBLIC_IP
```

Output ko `EC2_KNOWN_HOSTS` secret mein copy karein. Bina verify ki hui host key istemal na karein. Private key ko GitHub Secrets mein rakhein; kabhi repository mein commit na karein.

## Deploy karein

Ab `main` branch par push karne se `.github/workflows/deploy.yml` app build karega, JAR ko SSH ke zariye EC2 par copy karega aur service restart karega. Manually chalane ke liye GitHub mein **Actions → Build and deploy to EC2 → Run workflow** kholen.

App `http://EC2_PUBLIC_IP:8080` par kholen. Deployment fail ho to EC2 par logs dekhein:

```bash
sudo systemctl status java-demo
sudo journalctl -u java-demo -n 100 --no-pager
```
