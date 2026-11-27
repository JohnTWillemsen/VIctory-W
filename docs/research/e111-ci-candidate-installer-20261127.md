# E111 — CI-candidate ZIP verifier and crash-safe launcher for E108 / E109

Allows users to install a **source-verified** E108 or E109 public-source CI executable side-by-side (never overwrites old builds). It validates exactly two archive members; known candidate manifest version and exact source Git SHA, parent ancestry/provenance and diagnostics feature; the embedded executable SHA256 against the local extracted exe. Optional `-Launch` checks NVIDIA RTX5090, downloads exact pinned E087 crash monitor, and requires typing PLAY. No title access/launch by default.

**Caveat:** a self-reported manifest SHA256 proves consistency of the downloaded ZIP members, not cryptographic authenticity of CI itself. Only use artifacts downloaded from the linked successful GitHub Actions run. The installer has both expected source heads hardcoded; any later rebuild requires an explicit source-pin update and new Windows acceptance.

**E108** source code patch `b66e63d6a1869151e5729eec5584026991c5676b`, currently CI commit `70a58749a1b6bce7f4f215aaffd06d4cf07d00d4`, full upstream #2920 wave barrier.
**E109** source code patch `94e3871de5a8625f2e6580a47d9612802656ffd9`, currently CI commit `8c8498e72f4bd46925ed07cf562947fccfc33bf1`, full #3426+#3561 stack with two documented integration-context resolutions.

Owner RTX5090 runtime tests of these candidate builds have NOT yet happened. E111 synthetic WinPS5.1 tests should verify good E108/E109 ZIP acceptance, wrong source, unexpected archive members, corrupt executable SHA and no title launch by default. This is *not* a GPU crash fix; it only makes candidate handling safer.
