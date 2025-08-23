sudo apt update && sudo upgrade -y
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu
sudo systemctl start docker
sudo systemctl enable docker
git clone https://github.com/WeslleiBrito/Projeto-Pokedex.git
cd Projeto-Pokedex/
docker build -t test-app .
docker run -d --name test-app -p 8080:80 nginx
