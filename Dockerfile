FROM ubuntu:trusty
MAINTAINER Marcus Stong, marcus@andyet.net

RUN apt-get update && apt-get -y upgrade && apt-get -y install git xvfb sqlite3 python-pip wget chromium-browser; \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -; \
    sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'; \
    apt-get update && apt-get -y install google-chrome-stable; \
    git clone https://anon:anon@github.com/stongo/webrtc-tester.git /root/webrtc-tester; \
    cd /root/webrtc-tester; \
    git checkout dockerify; \
    chmod +x test-runner.sh; \
    chmod +x test-browser.sh
WORKDIR /root/webrtc-tester
ENTRYPOINT ["./test-browser.sh"]