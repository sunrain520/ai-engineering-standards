package com.example.order;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface OrderMapper {
  String findOne();
}
