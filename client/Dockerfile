FROM ubuntu:18.04

RUN apt-get update \ 
&&    apt-get install -y wget gnupg

COPY install-packages.sh .
RUN ./install-packages.sh

COPY bluecherry.conf /root/.config/bluecherry/

RUN export QT_GRAPHICSSYSTEM="native"

RUN export QT_X11_NO_MITSHM=1

CMD /usr/bin/bluecherry-client
