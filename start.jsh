/**
* This file is to be used by jshell
* only need to run once in jshell:
*  /set start -retain C:\myCodes\myjava\0_system_files\src\examples\start.jsh
* /list -all
*/

import java.io.*;
import java.math.*;
import java.net.*;
import java.nio.file.*;
import java.util.*;
import java.time.*;
import java.math.BigDecimal;
import java.math.RoundingMode;
/*
import java.time.LocalDateTime;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
*/
import java.util.Random;
import java.util.stream.Stream;
import java.util.Optional;



public void msg(Object o){
	System.out.println(o.toString());
}

public void dump(List<?> list) {
    System.out.println("-".repeat(80));
    System.out.println("total "+list.size());
    list.forEach((Object a) -> System.out.println(a));
}


class User {
    private String name;
    private int age;
    private Double salary;
    private int id;
    private List<Address> addresses;

    public List<Address> getAddresses() {
        return addresses;
    }

    public void setAddresses(List<Address> o) {
        this.addresses = o;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getId() {
        return id;
    }

    public Double getSalary() {
        return salary;
    }

    public void setSalary(Double salary) {
        this.salary = salary;
    }

    public User(int id, String name, int age, Double salary) {
        this.id = id;
        this.name = name;
        this.age = age;
        this.salary = salary;
    }

    public User(int id, String name, int age) {
        this.id = id;
        this.name = name;
        this.age = age;
    }

    public User(int id, String name) {
        this.id = id;
        this.name = name;
    }

    @Override
    public String toString() {
        return "User{" +
                "name='" + name + '\'' +
                ", age=" + age +
                ", salary=" + salary +
                ", id=" + id +
                ", addresses=" + addresses +
                '}';
    }
}

class Address {
    private String name;
    private int code;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public Address(String name, int code) {
        this.name = name;
        this.code = code;
    }

    @Override
    public String toString() {
        return "Address{" +
                "name='" + name + '\'' +
                ", code=" + code +
                '}';
    }
}


List<Integer> list3 = new ArrayList<>();
List<String> list2 = new ArrayList<>();
List<User> list1 = new ArrayList<>();
Map<String, User> map1 = new HashMap<>();

int count = 17;
Random r = new Random();
for (int i = 0; i < count; i++) {
    int k = r.nextInt(100);
    list3.add(k);
    list2.add("str " + k);

    Double sa = r.nextDouble() + r.nextInt(10000);
    BigDecimal b = new BigDecimal(sa).setScale(2, RoundingMode.CEILING);

    User u = new User(i, "name:" + i, k, b.doubleValue());
    List<Address> t = Arrays.asList(
            new Address("address of user " + i, k + 1029),
            new Address("address of user " + i, k + 8737),
            new Address("address of user " + i, k + 67),
            new Address("address of user " + i, k + 9872),
            new Address("address of user " + i, k + 1908),
            new Address("address of user " + i, k + 6834)
    );
    u.setAddresses(t);
    list1.add(u);
    map1.put("user:" + i, u);
}
// add some duplicated id User
list1.add(new User(3, "name-3333-1", 3333, 333.333));
list1.add(new User(3, "name-3333-2", 3334, 333.222));
list1.add(new User(5, "name-5555-1", 5555, 555.555));
list1.add(new User(5, "name-5555-2", 5555, 555.222));

String s = "hello,world,me,me,world";
Set<String> set1 = new HashSet<>(Arrays.asList(s.split(",")));
Stream<User> stream1=list1.stream();
Stream<Integer> stream3=list3.stream();
Stream<String> stream2=list2.stream();
