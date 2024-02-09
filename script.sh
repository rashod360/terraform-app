#!/bin/bash
sudo apt-get update -y
sudo apt-get install python3-venv -y
sudo apt install git

mkdir /home/ubuntu/Code
cd /home/ubuntu/Code
git clone https://github.com/mreschke/flask-hello-world.git

cd flask-hello-world
sudo python3 -m venv env
source env/bin/activate
pip install gunicorn
pip install -r requirements.txt

echo -e '[Unit]\nDescription=Gunicorn instance for a the "app" app\nAfter=network.target\n[Service]\nUser=ubuntu\nGroup=www-data\nWorkingDirectory=/home/ubuntu/Code/flask-hello-world\nExecStart=/home/ubuntu/Code/flask-hello-world/env/bin/gunicorn --bind localhost:8000 app:app\nRestart=always\n[Install]\nWantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/app.service

sudo systemctl daemon-reload
sudo systemctl start app
sudo systemctl enable app

sudo apt-get install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

sudo sed -i '21 i upstream app {server 127.0.0.1:8000;}' /etc/nginx/sites-available/default
sudo sed -i '52 i proxy_pass http://app;' /etc/nginx/sites-available/default
sudo sed -i  '53 s/^/#/' /etc/nginx/sites-available/default
sudo systemctl restart nginx