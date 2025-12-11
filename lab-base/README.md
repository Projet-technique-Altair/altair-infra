# Altaïr Lab Base Image

The **lab-base** image is the minimal foundation for all future lab environments of the Altaïr learning platform.  
It provides a lightweight Linux environment suitable for running simple commands, teaching exercises, and serving as a parent image for more advanced labs.

This base image is intentionally small, stable, and version-pinned to ensure reproducibility across all development machines and CI environments.

---

## 🔍 What is this image?

This is a **minimal Docker image based on Alpine Linux 3.20**, enriched only with:

- `bash`  
- `coreutils` (ls, cp, mv, mkdir, etc.)
- `curl`  
- `nano`  
- A non-root user: `student`
- A default working directory: `/home/student`

It is the starting point for every future lab image (Linux basics, Git, Python, Cyber labs, etc.).

---

## 🛠️ Build the Image (Local Development)

Inside the lab-base/ directory:

docker build -t altair-lab-base:3.20 .


Verify the image:

docker images | grep altair-lab-base


Run it interactively:

docker run -it altair-lab-base:3.20


If everything works, you should see:

student@container:~$