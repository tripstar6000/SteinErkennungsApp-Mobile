FROM nginx:alpine
# Railway source deploy trigger: Anlage mode
COPY index.part*.b64 /tmp/
RUN cat /tmp/index.part*.b64 | tr -d '\r\n' | base64 -d | gzip -d > /usr/share/nginx/html/index.html \
    && test -s /usr/share/nginx/html/index.html \
    && grep -Fq "Ich steh an der Anlage" /usr/share/nginx/html/index.html \
    && grep -Fq "CCMT 09T304" /usr/share/nginx/html/index.html \
    && grep -Fq "WNMG 080408" /usr/share/nginx/html/index.html \
    && rm -f /tmp/index.part*.b64
COPY manifest.webmanifest /usr/share/nginx/html/manifest.webmanifest
COPY sw.js /usr/share/nginx/html/sw.js
COPY icon.svg /usr/share/nginx/html/icon.svg
COPY apple-touch-icon.png /usr/share/nginx/html/apple-touch-icon.png
COPY icon-192.png /usr/share/nginx/html/icon-192.png
COPY icon-512.png /usr/share/nginx/html/icon-512.png
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
