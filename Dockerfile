# 1. Create an image with python2, python3, R, install a set of requirements and upload it to docker hub.
# Ahsan Lake

FROM python:3.11.5-bullseye

RUN apt update && apt install -y python && apt install r-base -y

WORKDIR /app
COPY . .

CMD ["sh", "-c", "tail -f /dev/null"]
EXPOSE 3000

## Docker push example
## docker tag python_latest:latest alake28/python_test:latest
## sudo docker push alake28/python_test:latest
##
## docker tag {local_image} {USER/repo:tag}
## docker push {USER/repo:tag}

# sudo docker push alake28/python_test:latest
# The push refers to repository [docker.io/alake28/python_test]
# 98617147055b: Pushed 
# 0c8e15886ff5: Pushed 
# 13b2ee28cbbf: Pushed 
# ce57cd18bc58: Pushed 
# 0e2c02944b26: Pushed 
# 4b6624637f9b: Pushed 
# c4e7c4259edf: Pushed 
# 061b0b8b2379: Pushed 
# c4f0a3489f63: Pushed 
# 8b6d3ee881ba: Pushed 
# 3dcc62b22ecb: Pushed 
# latest: digest: sha256:4668d28e0f9cf607afb73a934a7b4198b77a8d341ec5b1fbc89bc4f7dc853e4e size: 2635

# How to run built-in docker scout to search for CVE's. 
# docker scout quickview
# INFO New version 0.24.1 available (installed version is 0.20.0)
#     ✓ Image stored for indexing
#     ✓ Indexed 854 packages

#   Your image  python_test:latest     │    0C     0H     7M   148L     4?   
#   Base image  python:3-bullseye      │    0C     0H     7M   139L     4?   
#   Updated base image  python:alpine  │    0C     0H     0M     0L          
#                                      │                  -7   -139     -4   


# Running the following command will give more info on specific CVE's and links to remedies
# docker scout cves python_test:latest
# ex. libxslt 1.1.34-4+deb11u1
# pkg:deb/debian/libxslt@1.1.34-4+deb11u1?os_distro=bullseye&os_name=debian&os_version=11

#     ✗ LOW CVE-2015-9019
#       https://scout.docker.com/v/CVE-2015-9019
#       Affected range : >=1.1.34-4+deb11u1  
#       Fixed version  : not fixed  

# To avoid deploying dangerous packages, it is important ot run this scan or a similar scan in the CI/CD process.
# Once caught, the pipeline must be stopped and reporting can be made via a communication medium like slack or email to
# notify stakeholders and project teams that the application cannot be deployed until the CVE's and Vulnerabilities are remedied.