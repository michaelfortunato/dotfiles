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

FROM texlive/texlive:latest AS build-machine

FROM build-machine AS build
# Unfortuantely this means that this layer will be everytime 
# any file in the repo is changed. We relay on make to cache outputs
COPY main.tex main.tex
RUN latexmk -pdf -synctex=true -aux-directory=./aux main.tex \
  && mkdir -p /output && cp main.pdf /output

FROM scratch AS output
COPY --from=build /output /
