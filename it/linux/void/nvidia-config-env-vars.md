
```
/e/profile.d> cat 10-nvidia-gbm.sh
#!/bin/sh
export GBM_BACKEND=nvidia-drm

/e/profile.d> cat 11-nvidia-vaapi.sh
#!/bin/sh
export LIBVA_DRIVER_NAME=nvidia
export VDPAU_DRIVER=nvidia
```
