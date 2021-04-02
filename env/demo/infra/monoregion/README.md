# Terraform monoregion template

## Monoregion with just one frontend server

Small needs, just deploy one frontend instance.

```
      [GRA5]
        |
--------------------- Ext-net
        |
    [frontend1]
        |
--------------------- Int-net
```

## Monoregion with multiple frontend servers

Horizontal production, deploy multiple instances on the same region.

```
                              [GRA5]
                                |
------------------------------------------------------------------ Ext-net
        |                       |                      |
    [frontend1]            [frontend2]            [frontendX]
        |                       |                      |
------------------------------------------------------------------ Int-net
```

## Monoregion with one frontend server and multiple backend servers

Load balancing is needed, add instances to load balance your trafic on backend applications

```
      [GRA5]
        |
--------------------- Ext-net
        |
    [frontend1]
        |
--------------------- Int-net
        |
[b1-1] ... [b1-X]
```

## Monoregion with multiple frontend servers and multiple backend servers

Load balancing is needed and you need multiple frontend to scale your frontend workload.

```
                              [GRA5]
                                |
------------------------------------------------------------------ Ext-net
        |                       |                      |
    [frontend1]            [frontend2]            [frontendX]
        |                       |                      |
------------------------------------------------------------------ Int-net
                                |
                        [b1-1] ... [b1-X]
```
