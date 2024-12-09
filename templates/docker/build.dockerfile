# This dockerfile shows how you can define layers so that 
# they are reusuable. For this project 
# we had two buildsystems, one for building the latex pdf and 
# the other for building python code. 
# By seperating the build-base from dev-env
# The person on all aspects of the repo can create a container with the dev-env
# layer, while the person working on latex can use build-base
# In the future I might consider having a sperate python layer (slim) from the
# Then for the total "dev" environment, I will just copy the necessary 
# tex live distribution over. But that is really not great because
# its prone to error. In a sense, a build machine with latex and python 
# is what this project warranted, a custom setup, so it deserves a custom 
# layer!
# Stage 1: Build Base, aka the system environment we need to 
# Get our project up and ready
FROM texlive/texlive:latest AS build-base

# Note that make is our runner program
RUN apt-get update && apt-get install -y bash python3.12 python3.12-venv python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
SHELL ["/bin/bash", "-c"]

# Stage 2: This creates a build layer suitable for running the paper locally
# NOTE: Use it with docker-shell to build developer environments to test :)
FROM build-base AS dev-env
WORKDIR /app 
# WARN: Installing the system requirements of a python project
# should only depend on the manifest. Because python is interpretted.
COPY requirements.txt requirements.txt
RUN python3 -m venv venv && source venv/bin/activate && \
  pip3 install -r requirements.txt

FROM dev-env AS build-artifacts
COPY . .
RUN make artifacts && cp /app/bin/* /artifacts

FROM build-base AS build-paper
WORKDIR /app
COPY . .
COPY --from=build-artifacts /artifacts/* ./bin/ 
RUN make pdf

# scratch is a special 0 sized docker image
FROM scratch AS paper
COPY --from=build-paper /app/bin/main.pdf /main.pdf

FROM dev-env
COPY . .
CMD ["sleep", "infinity"]
