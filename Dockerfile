FROM mariadb:latest

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y curl
RUN apt-get install -y mysql-client

ADD cluster.cnf /etc/mysql/conf.d/cluster.cnf
RUN chmod 644 /etc/mysql/conf.d/cluster.cnf

ADD run.sh /run.sh

EXPOSE 3306 4567 4568 4444

RUN chmod +x /run.sh

CMD /run.sh
