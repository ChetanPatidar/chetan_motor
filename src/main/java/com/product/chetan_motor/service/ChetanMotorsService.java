package com.product.chetan_motor.service;

import com.product.chetan_motor.model.HostMaster;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class ChetanMotorsService {

    @Autowired
    RestTemplate restTemplate;

    public String getHelloStringService(){
        return "Hello from Service class";
    }

    public String getHelloStringService(String helloParams) {
        HostMaster emp = restTemplate.getForObject("http://localhost:8080/datacenter/gethostdetails", HostMaster.class);
        return "Hello from param Service class::" + emp;
    }

    public String getHelloStringService(String hello_params, String param1, Object o, Object o1, Object o2) {
        return hello_params + ":::" + param1;
    }
}
