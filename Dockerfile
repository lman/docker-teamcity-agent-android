FROM jetbrains/teamcity-minimal-agent:2017.1.2
MAINTAINER Pavel Sviderski <ps@stepik.org>

ENV USER buildagent
ENV HOME /home/$USER
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_TOOLS_REVISION 24.4.1

# Prepare the build agent to start as the buildagent user
RUN apt-get install --no-install-recommends -y git git-crypt \
    # required to build/install fastlane
    ruby ruby-dev g++ make \
 && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64" \
 && chmod +x /usr/local/bin/gosu \
 && chown -R $USER:$USER /opt/buildagent \
 && sed -i 's/${AGENT_DIST}\/bin\/agent.sh start/gosu buildagent ${AGENT_DIST}\/bin\/agent.sh start/' \
    /run-agent.sh

# Import the Let's Encrypt Authority certificate for Java to accept TeamCity server certificate
RUN curl -o /root/lets-encrypt.der https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.der \
 && $JRE_HOME/bin/keytool -trustcacerts -keystore $JRE_HOME/lib/security/cacerts -storepass changeit \
    -noprompt -importcert -alias lets-encrypt-x3-cross-signed -file /root/lets-encrypt.der \
 && rm /root/lets-encrypt.der

# Install Android command line tools
RUN curl https://dl.google.com/android/android-sdk_r${ANDROID_SDK_TOOLS_REVISION}-linux.tgz | tar xz -C /opt \
 && chown -R $USER:$USER $ANDROID_HOME

# Install Android licenses to not accept them manually during builds
ADD licenses.tar.gz $ANDROID_HOME/

# Install Android extra repos
RUN echo y | gosu $USER $ANDROID_HOME/tools/android update sdk --no-ui --all --filter \
    extra-android-m2repository,extra-google-m2repository

# Install fastlane
RUN gosu $USER gem install --no-document --user-install fastlane

ENV PATH $HOME/.gem/ruby/2.3.0/bin:$PATH
