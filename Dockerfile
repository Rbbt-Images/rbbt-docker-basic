FROM mikisvaz/rbbt-system
ADD provision.sh /tmp/provision.sh
RUN chmod +x /tmp/provision.sh
RUN /bin/bash /tmp/provision.sh
ENV HOME /home/rbbt
USER rbbt
