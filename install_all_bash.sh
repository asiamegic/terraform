sudo apt update
mkdir app
cd app
git init
git pull https://github.com/asiamegic/weight-tracker.git
rm -r node_modules
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install nodejs
npm init -y
npm install @hapi/hapi@19 @hapi/bell@12 @hapi/boom@9 @hapi/cookie@11 @hapi/inert@6 @hapi/joi@17 @hapi/vision@6 dotenv@8 ejs@3 postgres@1
npm install --save-dev nodemon@2
rm .env
touch .env
nano .env
sudo npm install pm2 -g
sudo pm2 start src/index.js
sudo pm2 save
sudo pm2 startup
sudo pm2 list