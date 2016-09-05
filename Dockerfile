FROM jetbrains/teamcity-minimal-agent:10.0.1
MAINTAINER Pavel Sviderski <ps@stepik.org>

ENV USER buildagent
ENV ANDROID_HOME /opt/android-sdk-linux
ENV ANDROID_SDK_TOOLS_REVISION 24.4.1
ENV ANDROID_SDK_VERSION 24

# Prepare the build agent to start as the buildagent user
RUN apt-get install --no-install-recommends -y sudo git git-crypt \
 && chown -R $USER:$USER /opt/buildagent \
 && sed -i 's/${AGENT_DIST}\/bin\/agent.sh start/sudo -Eu buildagent ${AGENT_DIST}\/bin\/agent.sh start/' \
    /run-agent.sh

# Import the Let's Encrypt Authority certificate for Java to accept TeamCity server certificate
RUN curl -o /root/lets-encrypt.der https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.der \
 && $JRE_HOME/bin/keytool -trustcacerts -keystore $JRE_HOME/lib/security/cacerts -storepass changeit \
    -noprompt -importcert -alias lets-encrypt-x3-cross-signed -file /root/lets-encrypt.der \
 && rm /root/lets-encrypt.der

# Install Android SDK
RUN curl https://dl.google.com/android/android-sdk_r${ANDROID_SDK_TOOLS_REVISION}-linux.tgz | tar xz -C /opt \
 && chown -R $USER:$USER $ANDROID_HOME \
 && echo y | sudo -u $USER $ANDROID_HOME/tools/android update sdk --no-ui --all --filter \
    android-$ANDROID_SDK_VERSION,extra-android-m2repository,extra-google-m2repository
