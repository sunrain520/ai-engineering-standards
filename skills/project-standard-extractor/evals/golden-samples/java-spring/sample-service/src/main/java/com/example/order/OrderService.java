package com.example.order;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {
  @Transactional
  public String listOrders() {
    return "ok";
  }
}
