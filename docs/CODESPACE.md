# Codespace setup

## Start

Create a Codespace from the `main` branch of
[vsdip/vsd-fpga-scl1d](https://github.com/vsdip/vsd-fpga-scl1d).

The devcontainer starts an XFCE desktop and noVNC on port 6080. Open the
**Ports** tab in Codespaces, then open the forwarded port 6080 in your browser.
The VPR GUI uses display `:1`.

## Install and check the SCL PDK

Upload the authorised archive, named `SCL 1.2 µm PDK.zip`, into the repository
root of the Codespace. The archive and unpacked PDK are excluded from Git.

```bash
cd /workspaces/vsd-fpga-scl1d
make install-pdk ARCHIVE="$PWD/SCL 1.2 µm PDK.zip"
make doctor
make inspect
