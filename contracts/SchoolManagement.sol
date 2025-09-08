// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SchoolManagement {
    enum Status {
        ACTIVE,
        DEFERRED,
        RUSTICATED
    }

    struct Student {
        uint256 id;
        string name;
        uint256 age;
        Status status;
        bool exists;
    }

    Student[] public students;
    uint256 public nextStudentId;
    uint256 public totalStudents;

    event StudentRegistered(uint256 indexed id, string name, uint256 age);
    event StudentUpdated(uint256 indexed id, string name, uint256 age);
    event StudentDeleted(uint256 indexed id);
    event StatusChanged(uint256 indexed id, Status newStatus);

    constructor() {
        nextStudentId = 1;
        totalStudents = 0;
    }

    function registerStudent(string memory _name, uint256 _age) public {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_age > 0, "Age must be greater than 0");

        Student memory newStudent = Student({
            id: nextStudentId,
            name: _name,
            age: _age,
            status: Status.ACTIVE,
            exists: true
        });

        students.push(newStudent);
        nextStudentId++;
        totalStudents++;

        emit StudentRegistered(newStudent.id, _name, _age);
    }

    function updateStudent(
        uint256 _id,
        string memory _name,
        uint256 _age
    ) public {
        uint256 index = findStudentIndex(_id);
        require(index < students.length, "Student not found");
        require(students[index].exists, "Student has been deleted");

        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_age > 0, "Age must be greater than 0");

        students[index].name = _name;
        students[index].age = _age;

        emit StudentUpdated(_id, _name, _age);
    }

    function deleteStudent(uint256 _id) public {
        uint256 index = findStudentIndex(_id);
        require(index < students.length, "Student not found");
        require(students[index].exists, "Student already deleted");

        students[index].exists = false;
        totalStudents--;

        emit StudentDeleted(_id);
    }

    function changeStudentStatus(uint256 _id, Status _newStatus) public {
        uint256 index = findStudentIndex(_id);
        require(index < students.length, "Student not found");
        require(students[index].exists, "Student has been deleted");

        students[index].status = _newStatus;

        emit StatusChanged(_id, _newStatus);
    }

    function getStudent(
        uint256 _id
    )
        public
        view
        returns (
            uint256 id,
            string memory name,
            uint256 age,
            Status status,
            bool exists
        )
    {
        uint256 index = findStudentIndex(_id);
        require(index < students.length, "Student not found");

        Student memory student = students[index];
        return (
            student.id,
            student.name,
            student.age,
            student.status,
            student.exists
        );
    }

    function getAllActiveStudents() public view returns (Student[] memory) {
        Student[] memory activeStudents = new Student[](totalStudents);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < students.length; i++) {
            if (students[i].exists) {
                activeStudents[currentIndex] = students[i];
                currentIndex++;
            }
        }

        return activeStudents;
    }

    function getAllStudents() public view returns (Student[] memory) {
        return students;
    }

    function findStudentIndex(uint256 _id) internal view returns (uint256) {
        for (uint256 i = 0; i < students.length; i++) {
            if (students[i].id == _id) {
                return i;
            }
        }

        return students.length;
    }

    function getTotalActiveStudents() public view returns (uint256) {
        return totalStudents;
    }

    function getTotalStudentsEverRegistered() public view returns (uint256) {
        return students.length;
    }

    function getStudentsByStatus(
        Status _status
    ) public view returns (Student[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < students.length; i++) {
            if (students[i].exists && students[i].status == _status) {
                count++;
            }
        }

        Student[] memory filteredStudents = new Student[](count);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < students.length; i++) {
            if (students[i].exists && students[i].status == _status) {
                filteredStudents[currentIndex] = students[i];
                currentIndex++;
            }
        }

        return filteredStudents;
    }
}
