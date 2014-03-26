# Dockerfile for the CEA Patavi worker
# You need the patavi/worker base image from http://github.com/gertvv/patavi-docker

FROM patavi/worker

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q libgmp-dev

RUN R -e 'install.packages("smaa", repos="http://cran.rstudio.com/"); if (!require("smaa")) quit(save="no", status=8)'
RUN R -e 'install.packages("mc2d", repos="http://cran.rstudio.com/"); if (!require("mc2d")) quit(save="no", status=8)'
RUN R -e 'install.packages("abind", repos="http://cran.rstudio.com/"); if (!require("abind")) quit(save="no", status=8)'

ADD R/cea.R /var/lib/patavi/cea_service.R

USER patavi
ENV HOME /var/lib/patavi
ENTRYPOINT ["/var/lib/patavi/bin/patavi-worker", "--method", "cea", "-n", "1", "--file", "/var/lib/patavi/cea_service.R", "--rserve", "--packages", "mc2d,smaa,abind"]
