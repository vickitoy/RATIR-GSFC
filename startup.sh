#
#
#!/bin/bash

#PROJECT_ROOT="$(cd $(dirname "$0"); pwd)"
PROJECT_ROOT="$(cd $(dirname "."); pwd)"

IDL_PATH=+$IDL_DIR/lib:+$PROJECT_ROOT/code/idl:+$PROJECT_ROOT/code/photometry4
export IDL_PATH


