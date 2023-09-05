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

In a CI/CD pipeline, you wouldn't want to be downloading and installing commonly used packages and languages at all. It's better to prebuild those images in as separate pipeline and validate them against CVE's. You will then have gold images that you can use on a per project basis that you know are secure and won't take up build time installing packages that you already know you will need. The pipeline for the project can then just have a Dockerfile that simply adds what the project needs (codebase and project specific requirements) and already has the base image layers of the rest. That will save on build time.

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

These can all be done in a Helm chart or Kubernetes manifest file. Since I've used Helm in this example so far, I'll use it as an example here as well. Helm is a Kubernetes package manager that allows for the packaging and deployment of Kubernetes applications. Helm contains Charts and Templates to allow a user to configure how they want their application to be deployed. Inside the deployment.yml you can see that you can define different images to deploy. These would be images already built in the CI/CD and pushed to the container registry. To use different base images, (the first layer of an image as it is being built) inside the github actions example here, you can select from different dockerfiles that start with different base images and built the requirements on top of them. Packages are much of the same idea. During the build step of a pipeline, the dockerfile that you choose will contain the declaration of the Base image and the rest of the packages to be installed. You can go one step forward in the automation and create a number of base images that contain various commonly used environments (linux flavor + packages + configurations on the container) and handle all of that outside of the project. That way the Dockerfile in a codebase will pull from an organizations prebuilt stable base images that have been checked for CVE's and have all the commonly used requirements already baked into the image. 

Mem/CPU requests can be handled in a Helm chart to better provide a specific application level request of resources. Kubernetes allows for deployments to make requests on a machines CPU or Memory in order to allow the kubelet and other management components to schedule pods correctly on host nodes. Having various values files depending on environment and other factors is a good way to make sure that the application is using the correct resources and may not be over or under provisioned. This is also important in tuning an application for autoscaling and performance optimization. GPU requests are not natively in kubernetes and could be done by evaluating the gpu usage of a container and determining what type of instance type the container would ultimately live in. If there are GPU intensive workloads being run on an application, you could deploy GPU optimized EC2s to the cluster and create nodegroup deployments to send the application containers to those specific nodes. An example of this is in the example codebase, the deployments.yaml file has a template to access values for nodeselectors, taints, and tolerations which are all ways to define in a helm deployment how you want the containers to deployed in a kubernetes cluster. Furthermore, it seems possible, but I have never done it, to use a plugin for kubernetes for nvidia/gpu limits. 

https://catalog.ngc.nvidia.com/orgs/nvidia/containers/gpu-operator
https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/

2. Monitor each environment and make sure that:
a. Resources request is accurate (requested vs used)
b. Notify when resources are idle or underutilized
c. Downscale when needed (you can assume any rule defined by you to allow this
to happen)
d. Save data to track people requests/usage and evaluate performance

Monitoring on a Cluster level can be done to see if resource requests and/or limits are being set properly. You can set the resource requests in the deployment of the application. You can pull this data for monitoring purposes by describing a deployment and describing the replica set. In order to see if the requests that are being made to the nodes are accurate, you can use the built-in metrics tools and/or third party tools like prometheus to capture. Specifically you can quiery the metric servers for the kubelet to report on pod usage statistics. This data can be sent to a monitoring tool like cloudwatch or datadog to create views or even alerts if there are applications that are using more than their requested amount. Connecting an integration for Kubernetes/Prometheus to a tool like Datadog can provide a good platform for reporting on critical cluster metrics as well as application specific usage and performance metrics. The kubelet reports on the pod status, sends metrics over to the monitoring tool, which you can set up alerts for underutilized or idled containers. Moreso, the built-in metrics server can be made to work internally in the cluster with a horizontal pod autoscaler (HPA). The HPA is able to leverage the metrics pulled from the management plane to autoscale for metrics like cpu or memory against certain thresholds. An example of the HPA can be seen in the templates directory of this codebase with the values.yaml file being used to set the thresholds and what metrics to trigger the autoscaling events. 


3. The cluster needs to automatically handle up/down scaling and have multiple instance
groups/taints/tags/others to be chosen from in order to segregate resources usage
between teams/resources/projects/others

I touched on this topic in the other sections. You can define nodegroups, taints, tagging, and tolerances in kubernetes manifest files or helm charts. In this example it is done in a helm chart. You can see examples nodegroups allow you set selectors to only place deployed pods in certain nodegroups or nodes that are linked by labels. Taints are the opposite that allow you to set selectors that will have the kubelet avoid scheduling the deployed pods to those specific labeled nodes. Sample code would look like this: (Taken from the kubernetes docs on gpu selecting)

```
apiVersion: v1
kind: Pod
metadata:
  name: example-vector-add
spec:
  restartPolicy: OnFailure
  containers:
    - name: example-vector-add
      image: "registry.example/example-vector-add:v42"
      resources:
        limits:
          gpu-vendor.example/example-gpu: 1 # requesting 1 GPU


# Label your nodes with the accelerator type they have.
kubectl label nodes node1 accelerator=example-gpu-x100
kubectl label nodes node2 accelerator=other-gpu-k915
```

Cluster autoscaling is handled in two ways. Horizontal and Vertical. The Horizontal Pod Autoscaler (HPA) does a fine job autoscaling pods up and down across existing nodes that are selected by the pod deployment. At its most basic configuration, you select which metric you want to monitor, (CPU/Mem) what is the thresholds for autoscaling, and what are the min and max alloted pods to be deployed to the replicaset. With that configuration you can fine tune scaling on those metrics and and send the coinciding data to your observability platform to alert and monitor. Vertical autoscaling can be done using a number of 3rd party tools. I've personally used Karpenter in the past. Vertical autoscaling means that we are going to add nodes instead of pods. Horizontal autoscaling will still happen, but when Karpenter detects that the node groups are reaching a certain threshold of usage (resources or usage) it will trigger scaling of nodes to the cluster. This can be done to add or remove nodes based on usage.

4. SFTP, SSH or similar access to the deployed environment is needed so DNS handling
automation is required

I'm going to assume this is in relation to ssh, sftp, or other protocol access to Nodes in the cluster. Kubernetes has a built in DNS service for pods and services that does not usually require much configuration. The kubelet deals with most of the DNS communication between nodes and manages the /etc/resolv.conf files based on namespacing and other configurations of the cluster. Connecting ssh, sftp, and other protocol access to nodes themselves are going to be configured using the underlying nodes security rules. If we are talking about AWS here, those nodes would have their security groups configured to allow traffic from approved sources to those ports. 

5. Some processes that are going to run inside these environments require between
100-250GB of data in memory
a. Could you talk about a time when you needed to bring the data to the code, and
how you architected this system?
b. If you don’t have an example, could you talk through how you would go about
architecting this?
c. How would you monitor memory usage/errors?

Environments that require data in memory in my experience have been solved by using in memory datastores like redis or memcached. My experience with those have been creating pods using those tools or sending the data in memory to an AWS service like elasticache. Typically I am looking for solutions that deal with the data persistence, memory management, ttl's of the data, and how to architect the clusters. Memory management and TTL's of data are usually figured out in conjunction with the data engineer to configure the data in memory to be optimized and reduce bloat. Setting redis to run as a cluster is often times a good idea if the availability and recoverability of the data is important. Selecting the right instance types are important even if using an AWS managed service like elasticache. Selecting optimized memory instances will efficiently house in memory datastores. Monitoring memory usage for redis, for example, can be done with redis-cli or even prometheus. This allows time series metrics to be shipped to a monitoring platform like cloudwatch or datadog, or handled internally by scripts to monitor the usage of the memory and avoid issues. Logging should be forwarded as well to a log aggregator to store for troubleshooting or create monitors on trends in errors. Other tools like cloudwatch/datadog integrations can also be used to help monitor errors and other key metrics of in memory data.  

Troubleshooting
Try to solve the problems that might arise through the test by yourself (we are always available,
but we are looking forward to seeing your problem solving skills and ability to self serve).