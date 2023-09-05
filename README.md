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
3. Scan the recently created container and evaluate the CVEs that it might contain.
a. Create a report of your findings and follow best practices to remediate the CVE
b. What would you do to avoid deploying malicious packages?
4. Use the created image to create a kubernetes deployment with a command that will
keep the pod running
5. Expose the deployed resource
6. Every step mentioned above have to be in a code repository with automated CI/CD
7. How would you monitor the above deployment? Explain or implement the tools that you
would use
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