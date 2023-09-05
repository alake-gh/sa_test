General questions - Docker, CVEs, CI/CD, monitoring

1. Create an image with python2, python3, R, install a set of requirements and upload it to
docker hub.

I created 3 dockerfiles. One dockerfile with an inefficient ordering in the dockerfile, (Dockerfile.inefficient) another with an efficient ordering, (Dockerfile.efficient) and a Dockerfile with a simple webserver installed on it (Flask) to add another requirement. 

```
Docker push example
docker tag python_latest:latest alake28/python_test:latest
sudo docker push alake28/python_test:latest

docker tag {local_image} {USER/repo:tag}
docker push {USER/repo:tag}

sudo docker push alake28/python_test:latest
The push refers to repository [docker.io/alake28/python_test]
98617147055b: Pushed 
0c8e15886ff5: Pushed 
13b2ee28cbbf: Pushed 
ce57cd18bc58: Pushed 
0e2c02944b26: Pushed 
4b6624637f9b: Pushed 
c4e7c4259edf: Pushed 
061b0b8b2379: Pushed 
c4f0a3489f63: Pushed 
8b6d3ee881ba: Pushed 
3dcc62b22ecb: Pushed 
latest: digest: sha256:4668d28e0f9cf607afb73a934a7b4198b77a8d341ec5b1fbc89bc4f7dc853e4e size: 2635
```


2. For the previously created image
a. Share build times
b. How would you improve build times?

Refer to the comments in Dockerfile.efficient and Dockerfiile.inefficient to see the build times between two different dockerfiles doing the same thing. 

Dockerfile.inefficient
```
Building 205.9s (10/10) FINISHED -> Original Build
Building 203.9s (10/10) FINISHED -> after code changes. Very inefficient because container images and docker work in layers. The code changes being detected early in the container build means that the package and requirements installs after must be run again.
```

Dockerfile.efficient
```
Building 235.4s (10/10) FINISHED   --> Original build 
Building 0.5s (9/9) FINISHED   -> after code changes the build is almost instant because the main time sinks are already cached and have not changed    
```

Other things to keep in mind. You can use lighter images to save on build times. Alpine based linux images will produce less bloat than a full debian install. There will be some more overhead work to install all that is needed, but you also keep the image lightweight and secure. Understanding how layers work will also reduce build times, you want to combine layers and make them step-wise easy to understand and work with so certain parts of the build remain in cache effecitively. Using direct tags instead of :latest in the FROM statement should also be done for both security and build speed reasons.

3. Scan the recently created container and evaluate the CVEs that it might contain.
a. Create a report of your findings and follow best practices to remediate the CVE
b. What would you do to avoid deploying malicious packages?

```
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
```

I've used tools like Sonarcube and docker scout. You want to include these tools as part of your image building process. After an image creation, the scan will check for CVEs. A good practice is to immediately report to Slack/Email or create automated jira tickets on High/Criticals. Remediation is typically going into package managers and updating requirements. For example, if you are working with Node, you might have to uptick a version in the Package.json to remedy a CVE and rerun the build. However, this often comes in a coordinated effort with the dev team as changing versions can break or degrade code operation. High and Critical CVE's should warrant stopping a deployment and notifying stakeholders about the risks involved.

4. Use the created image to create a kubernetes deployment with a command that will
keep the pod running

Included in the repo is a mock helm deploy written out. Much of this is templated to be controlled by the values.yaml to provide modularity, simplicity, and editability, of a template heavy deployment strategy. I'll go into more detail about various choices and structure decisions being mocked here that should satisfy some of the more advanced requirements.

```
helm install -f values.yaml sa-test .

kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
sa-test-6bf8495898-px9j7   1/1     Running   0          50m


```
5. Expose the deployed resource

```
kubectl get svc sa-test
NAME      TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
sa-test   ClusterIP   10.108.2.43   <none>        8080/TCP   51m

kubectl get ingress
NAME      CLASS    HOSTS                 ADDRESS   PORTS   AGE
sa-test   <none>   chart-example.local             80      51m
```
I set up a ClusterIP setup with a simple ingress resource in front of this. Typically in the cloud, ingress would be dependant on the platform being deployed to. For example, AWS ingress controller is used for setting up ELB/ALB resources in AWS that reach out to nodes with exposed services. The keys to take away with exposing resources is to match internal service level traffic, using services or service meshes with external ingress with ingress controllers. 

6. Every step mentioned above have to be in a code repository with automated CI/CD

Refer to the repo and the .github/workflows directory to see a mock up of a github actions simple deployment pipeline. While not true CI or CD because we are not continuiously integrating code without testing here and its not CD because we are not validating anything on deployment to be able to continuiously deploy. This pipeline will keep everyting in the codebase and provide a very simple shell to build the container, run the container scan, and push it to dockerhub. The deploy steps mock a deployment to a release and prod environment. The difference between the two will come to the values.yaml which can be templated to serve the needs and requirements of the projects and environments. 

7. How would you monitor the above deployment? Explain or implement the tools that you
would use

Observability comes at a layered approach with good alerting and reporting. Some of this comes down to cost and complexity but I'll detail a standard approach. Firstly, let's put something like prometheus on the cluster level. Prometheus is open source and provides metric collection over time with excellent reporting to cluster and container level data. This tool will not only monitor the application deployment but also the management plane and other components that keep the cluster running. Dashboards and data can be created based of the raw data or be sent to a tool like Datadog using an integration to organize and create alerting based on the data. The K8s infra should be monitored for key metrics like; CPU, memory, bandwidth and latency, and disk io. Higher level cluster metrics can be pulled for number of pods in a deployment, node groups, events, etc. Prometheus provides a pretty decent log monitoring solution as well. Pulling application logs from container and management plane pods to aggregate and report. Implementing Prometheus is pretty straightforward, you would apply their supported Helm chart and configure the chart values if you have tuning or special configurations. Past that, if we are on AWS, you would use Cloudwatch or whatever 3rd party (Datadog/New Relic) to pull cloud metrics on the dependencies, ec2s, load balancers, DBs, etc, that surround the application. Creating dashboards and alerting on those based on the requirements of the app.

Project
Using kubernetes you need to provide all your employees with a way of launching multiple
development environments (different base images, requirements, credentials, others). The
following are the basic needs for it:
1. UI, CI/CD, workflow or other tool that will allow people to select options for:
a. Base image
b. Packages
c. Mem/CPU/GPU requests
2. Monitor each environment and make sure that:
a. Resources request is accurate (requested vs used)

b. Notify when resources are idle or underutilized
c. Downscale when needed (you can assume any rule defined by you to allow this
to happen)
d. Save data to track people requests/usage and evaluate performance
3. The cluster needs to automatically handle up/down scaling and have multiple instance
groups/taints/tags/others to be chosen from in order to segregate resources usage
between teams/resources/projects/others
4. SFTP, SSH or similar access to the deployed environment is needed so DNS handling
automation is required
5. Some processes that are going to run inside these environments require between
100-250GB of data in memory
a. Could you talk about a time when you needed to bring the data to the code, and
how you architected this system?
b. If you don’t have an example, could you talk through how you would go about
architecting this?
c. How would you monitor memory usage/errors?

Troubleshooting
Try to solve the problems that might arise through the test by yourself (we are always available,
but we are looking forward to seeing your problem solving skills and ability to self serve).