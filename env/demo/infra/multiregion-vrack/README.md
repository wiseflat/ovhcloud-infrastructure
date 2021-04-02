# Terraform monoregion cluster module

## Multiregion with one frontend per region and multiple backend instances

The vRack (virtual rack) technology enables your OVH services to be connected, isolated or spread across one or multiple private secure networks.

Keep your workload localy to a region but connect some of your applications (like your databases) on a distributed private network across regions.

```
              [UK1]                                     [DE1]                             [GRA5]
                |                                         |                                 |
-------------------------------- // --------------------------------------- // ----------------------------------   Ext-net
        |                                        |                                  |
    [frontend1]--------|                    [frontend1]---------|              [frontend1]--------|
        |              |                          |             |                   |             |
      -----            |                        -----           |                 -----           |              Int-net
        |              |                          |             |                   |             |
        |              |                          |             |                   |             |
[b1-1] ... [b1-X]      |                  [b2-1] ... [b2-X]     |           [b3-1] ... [b3-X]     |
                       |                                        |                                 |
------------------------------------------------------------------------------------------------------------ Multi-net (vrack)
                       |                                        |                                 |
               [b1-1] ... [b1-X]                        [b2-1] ... [b2-X]                 [b3-1] ... [b3-X]
```


## Multiregion with multiple frontend per region and multiple backend instances

Same infrastructure explained above.

```
              [UK1]                                     [DE1]                             [GRA5]
                |                                         |                                 |
-------------------------------- // --------------------------------------- // ----------------------------------   Ext-net
        |                                        |                                  |
 [f1-1]...[f1-X]-------|                  [f2-1]...[f2-X]-------|            [f3-1]...[f3-X]------|
        |              |                          |             |                   |             |
      -----            |                        -----           |                 -----           |              Int-net
        |              |                          |             |                   |             |
        |              |                          |             |                   |             |
[b1-1] ... [b1-X]      |                  [b2-1] ... [b2-X]     |           [b3-1] ... [b3-X]     |
                       |                                        |                                 |
------------------------------------------------------------------------------------------------------------ Multi-net (vrack)
                       |                                        |                                 |
               [b1-1] ... [b1-X]                        [b2-1] ... [b2-X]                 [b3-1] ... [b3-X]
```
