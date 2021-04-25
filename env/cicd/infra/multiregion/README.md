# Terraform multiregion template

## Multiregion with one frontend per region

It is the same design than the monoregion infrastructure but distributed over multiple compartmentalized region.

```
      [UK1]                   [DE1]                  [GRA5]
        |                       |                      |
------------------ // ---------------------- // ---------------------- Ext-net
        |                       |                      |
    [frontend1]            [frontend2]            [frontend1]
        |                       |                      |
------------------    ---------------------    ------------------ Int-net
```

## Multiregion with one frontend per region and multiple backend instances

Scale up your infrastructure by adding backend instances over multiple compartmentalized region.

```
      [UK1]                   [DE1]                  [GRA5]
        |                       |                      |
------------------ // ---------------------- // ---------------------- Ext-net
        |                       |                      |
    [frontend1]            [frontend1]            [frontend1]
        |                       |                      |
------------------    ---------------------    ------------------ Int-net
        |                       |                      |
[b1-1] ... [b1-X]       [b2-1] ... [b2-X]      [b3-1] ... [b3-X]
```
