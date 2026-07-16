# Container will continue running on exit
# Remove with `podman kill zisk-dev && podman rm zisk-dev`
{pkgs, ...}:
  pkgs.writeShellScriptBin "zisk-shell" ''
    set -e

    CONTAINER_NAME="''${ZISK_CONTAINER_NAME:-zisk-dev}"
    # CI publishes the tested image per branch; podman pulls it on first use,
    # so no local zisk-build is needed. Set ZISK_IMAGE=localhost/cargo-zisk:latest
    # to use a locally built image instead.
    IMAGE_NAME="''${ZISK_IMAGE:-ghcr.io/argumentcomputer/cargo-zisk:zisk-1.0}"
    SHELL="''${ZISK_SHELL:-/bin/bash}"

    DEVICE=
    KEY=
    SETUP=0

    usage() {
      cat <<EOF
    Usage: zisk-shell [OPTIONS]

    Enter a shell in the Zisk container. If setup options are passed, ziskup is
    run inside the container before the shell starts (use this to install or
    switch CPU/GPU binaries and setup keys).

    Options:
      --gpu, --cpu        Select GPU or CPU binaries
      --key KEY           Setup key: proving | proving-no-consttree | verify | none
      --provingkey        Shortcut for --key proving
      --verifykey         Shortcut for --key verify
      --nokey             Shortcut for --key none
      -h, --help          Show this help

    Environment:
      ZISK_CONTAINER_NAME (default: zisk-dev)
      ZISK_IMAGE          (default: ghcr.io/argumentcomputer/cargo-zisk:zisk-1.0;
                           set to localhost/cargo-zisk:latest for a zisk-build image)
      ZISK_SHELL          (default: /bin/bash)
    EOF
    }

    while [ $# -gt 0 ]; do
      case "$1" in
        --gpu) DEVICE=gpu; SETUP=1; shift ;;
        --cpu) DEVICE=cpu; SETUP=1; shift ;;
        --key) KEY="$2"; SETUP=1; shift 2 ;;
        --provingkey) KEY=proving; SETUP=1; shift ;;
        --verifykey) KEY=verify; SETUP=1; shift ;;
        --nokey) KEY=none; SETUP=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *)
          echo "zisk-shell: unknown option: $1" >&2
          usage >&2
          exit 1
          ;;
      esac
    done

    if [ -n "$KEY" ]; then
      case "$KEY" in
        proving|proving-no-consttree|verify|none) ;;
        *)
          echo "zisk-shell: invalid --key value: $KEY" >&2
          exit 1
          ;;
      esac
    fi

    PODMAN=${pkgs.podman}/bin/podman

    # Check if container exists
    if "$PODMAN" container exists "$CONTAINER_NAME"; then
      STATUS=$("$PODMAN" inspect -f '{{.State.Status}}' "$CONTAINER_NAME")

      if [ "$STATUS" != "running" ]; then
        echo "Starting stopped container: $CONTAINER_NAME"
        "$PODMAN" start "$CONTAINER_NAME"
      else
        echo "Container $CONTAINER_NAME is already running"
      fi
    else
      echo "Creating new container: $CONTAINER_NAME"
      "$PODMAN" run -dit \
        --name "$CONTAINER_NAME" \
        --privileged \
        --ulimit memlock=-1:-1 \
        --ipc=host \
        "$IMAGE_NAME" \
        "$SHELL"
    fi

    if [ "$SETUP" -eq 1 ]; then
      ZISKUP_ARGS=
      [ "$DEVICE" = "gpu" ] && ZISKUP_ARGS="$ZISKUP_ARGS --gpu"
      [ "$DEVICE" = "cpu" ] && ZISKUP_ARGS="$ZISKUP_ARGS --cpu"
      ENV_ARGS=
      if [ -n "$KEY" ]; then
        ENV_ARGS="-e SETUP_KEY=$KEY"
      fi
      echo "Running ziskup in container (device=''${DEVICE:-default}, key=''${KEY:-default})"
      # shellcheck disable=SC2086
      "$PODMAN" exec -it $ENV_ARGS "$CONTAINER_NAME" \
        /root/.zisk/bin/ziskup $ZISKUP_ARGS
    fi

    echo "Entering container... (container will persist after exit)"
    "$PODMAN" exec -it "$CONTAINER_NAME" "$SHELL"
  ''
