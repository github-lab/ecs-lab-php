FROM 761602622223.dkr.ecr.cn-north-1.amazonaws.com.cn/labphp5

# Install app
RUN rm -rf /var/www/*
ADD src /var/www

# Configure apache
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

EXPOSE 80

CMD ["/usr/sbin/apache2", "-D",  "FOREGROUND"]