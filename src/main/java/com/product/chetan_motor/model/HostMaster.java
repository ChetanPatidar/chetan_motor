package com.product.chetan_motor.model;

import lombok.*;

import javax.persistence.*;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class HostMaster {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private int hostId;
    @Column(name = "host_name")
    private String hostName;
    private String hostIp;
    private String hostIPV4;
    private String hostIPV6;

}
