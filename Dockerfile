# 1) Use alpine-based NodeJS base image (use Node.js v. 16)
FROM node:16

# 2) Install latest stable Chrome
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | \
    tee -a /etc/apt/sources.list.d/google.list && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | \
    apt-key add - && \
    apt-get update && \
    apt-get install -y google-chrome-stable libxss1

# 3) Install the Chromedriver version that corresponds to the installed major Chrome version
RUN google-chrome --version | grep -oE "[0-9]{1,10}.[0-9]{1,10}.[0-9]{1,10}" > /tmp/chromebrowser-main-version.txt
RUN wget --no-verbose -O /tmp/latest_chromedriver_version.txt https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$(cat /tmp/chromebrowser-main-version.txt)
RUN wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$(cat /tmp/latest_chromedriver_version.txt)/chromedriver_linux64.zip && rm -rf /opt/selenium/chromedriver && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium && rm /tmp/chromedriver_linux64.zip && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$(cat /tmp/latest_chromedriver_version.txt) && chmod 755 /opt/selenium/chromedriver-$(cat /tmp/latest_chromedriver_version.txt) && ln -fs /opt/selenium/chromedriver-$(cat /tmp/latest_chromedriver_version.txt) /usr/bin/chromedriver

# 4) Set the variable for the container working directory & create the working directory
ARG WORK_DIRECTORY=/program
RUN mkdir -p $WORK_DIRECTORY
WORKDIR $WORK_DIRECTORY

# 5) Install npm packages (do this AFTER setting the working directory)
RUN npm config set unsafe-perm true
RUN npm i selenium-webdriver nodemailer dotenv
ENV NODE_ENV=development NODE_PATH=$WORK_DIRECTORY

# 6) Copy script & env to execute to working directory
COPY index.js .
COPY .env .

EXPOSE 8080

# 7) Execute the script in NodeJS
CMD ["node", "index.js"]
