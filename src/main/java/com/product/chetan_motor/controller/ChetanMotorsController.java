package com.product.chetan_motor.controller;

import com.product.chetan_motor.model.HostMaster;
import com.product.chetan_motor.service.ChetanMotorsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

/*
Controller for Chetan Motors to perform motors CRUD operation
 */

@RestController
//Class Level Request Mapping.
@RequestMapping("/datacenter")
public class ChetanMotorsController {

    private Logger LOGGER = LoggerFactory.getLogger("ChetanMotorsController.class");

    @Autowired
    ChetanMotorsService chetanMotorsService;

    /**
     * This is my first endpoint which will return helo string for any request looking for hello.
     * Method level requets mapping.
     *
     * @return
     */
    @RequestMapping("/hello")
    public String getHello() {
        LOGGER.info("Inside controller class - getHello() method");
        //return chetanMotorsService.getHelloStringService();
        return chetanMotorsService.getHelloStringService("hello_params");
        //return chetanMotorsService.getHelloStringService("hello_params", "param1", null, null, null);
    }

    /**
     *
     */
    @RequestMapping(value = "/gethostdetails", produces = "application/json")
    public HostMaster getHostDetails() {
        HostMaster hostMaster = new HostMaster();
        hostMaster.setHostId(10001);
        hostMaster.setHostName("Hosy-123");
        hostMaster.setHostIp("10.10.10.10");
        hostMaster.setHostIPV4("102.102.102.102");
        hostMaster.setHostIPV6("102.f23-sh-djsh-sshe");
        LOGGER.info(hostMaster.toString());

        return hostMaster;
    }

    /**
     * Endoints for getting all hosts.
     */
    @RequestMapping("/getallhosts")
    public List<HostMaster> getAllDetails() {
        List<HostMaster> hostMasterList = new ArrayList<>();

        for (int i = 0; i < 2; i++) {
            HostMaster hostMaster = new HostMaster();
            hostMaster.setHostId(i);
            hostMaster.setHostName("Hosy-123::" + i);
            hostMaster.setHostIp("10.10.10.10::" + i);
            hostMaster.setHostIPV4("102.102.102.102::" + i);
            hostMaster.setHostIPV6("102.f23-sh-djsh-sshe::" + i);
            hostMasterList.add(hostMaster);
        }
        return hostMasterList;
    }

    //Implement CRUD Operation

    //Create Product
    @RequestMapping("/createproduct")
    public List<HostMaster> createProduct() {
        return null;
    }

    //Read Product
    @RequestMapping("/getproduct")
    public HostMaster getProduct() {
        return null;
    }

    //Update Product
    @RequestMapping("/updateproduct")
    public HostMaster updateProduct() {
        return null;
    }

    //Delete Product
    @RequestMapping("/deleteproduct")
    public HostMaster deleteProduct() {
        return null;
    }

}
