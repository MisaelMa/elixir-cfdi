# `mix releaser.status`
[🔗](https://github.com/MisaelMa/releaser/blob/main/lib/mix/tasks/releaser.status.ex#L1)

Shows which apps have version differences compared to what's published on Hex.

## Usage

    mix releaser.status

## Output

    Package              Local       Hex         Status
    cfdi_xml             4.0.19      4.0.18      ahead
    cfdi_csd             4.0.16      4.0.16      published
    cfdi_complementos    4.0.18-dev.1  4.0.17    pre-release
    my_new_app           0.1.0       —           unpublished

---

*Consult [api-reference.md](api-reference.md) for complete listing*
