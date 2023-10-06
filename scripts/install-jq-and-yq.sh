#/bin/bash
ARCHITECTURE=$(dpkg --print-architecture) 
YQ_BINARY=yq_linux_${ARCHITECTURE} 
YQ_VERSION=${YQ_VERSION:-"4.35.1"}
JQ_VERSION=${JQ_VERSION:-"1.7"}

# Install YQ
wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | \
  tar xz && mv ${YQ_BINARY} /usr/bin/yq

# Install JQ with wget
wget https://github.com/jqlang/jq/releases/download/jq-$JQ_VERSION/jq-linux-$ARCHITECTURE -O /usr/bin/jq && \
  chmod +x /usr/bin/jq