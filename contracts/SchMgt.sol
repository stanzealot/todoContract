// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SchMgt {
    uint256 public studentCount;
    uint256 public teacherCount;
    address public principal;

    enum Gender {
        male,
        female,
        other
    }
    enum Status {
        active,
        inactive,
        graduated
    }
    enum TeacherStatus {
        active,
        inactive,
        onLeave
    }

    struct Student {
        address studentAddress;
        string name;
        uint8 age;
        uint8 grade;
        Gender gender;
        Status status;
        mapping(string => uint8) scores; // subject => score
        string[] subjects; // list of subjects for iteration
    }

    struct Teacher {
        address teacherAddress;
        string name;
        uint8 age;
        Gender gender;
        string subject;
        TeacherStatus status;
        uint256 salary;
        uint256 hireDate;
    }

    mapping(uint256 => Student) public students;
    mapping(uint256 => Teacher) public teachers;
    mapping(address => uint256) public studentAddressToId;
    mapping(address => uint256) public teacherAddressToId;
    mapping(address => bool) public isTeacher;
    mapping(address => bool) public isStudent;

    // Events
    event StudentRegistered(
        uint256 indexed studentId,
        address indexed studentAddress,
        string name
    );
    event TeacherAdded(
        uint256 indexed teacherId,
        address indexed teacherAddress,
        string name,
        string subject
    );
    event ScoreUpdated(
        uint256 indexed studentId,
        string subject,
        uint8 score,
        address updatedBy
    );
    event StudentGradeUpdated(uint256 indexed studentId, uint8 newGrade);
    event TeacherStatusUpdated(
        uint256 indexed teacherId,
        TeacherStatus newStatus
    );

    modifier onlyPrincipal() {
        require(
            msg.sender == principal,
            "Only principal can call this function"
        );
        _;
    }

    modifier onlyTeacher() {
        require(isTeacher[msg.sender], "Only teachers can call this function");
        _;
    }

    modifier onlyPrincipalOrTeacher() {
        require(
            msg.sender == principal || isTeacher[msg.sender],
            "Only principal or teachers can call this function"
        );
        _;
    }

    constructor(address _principal) {
        principal = _principal;
        studentCount = 0;
        teacherCount = 0;
    }

    // ==================== STUDENT FUNCTIONS ====================

    function registerStudent(
        address _studentAddress,
        string memory _name,
        uint8 _age,
        Gender _gender
    ) public onlyPrincipal {
        require(_studentAddress != address(0), "Invalid student address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!isStudent[_studentAddress], "Student already registered");
        require(_age > 0 && _age < 100, "Invalid age");

        students[studentCount].studentAddress = _studentAddress;
        students[studentCount].name = _name;
        students[studentCount].age = _age;
        students[studentCount].grade = 1;
        students[studentCount].gender = _gender;
        students[studentCount].status = Status.active;

        studentAddressToId[_studentAddress] = studentCount;
        isStudent[_studentAddress] = true;

        emit StudentRegistered(studentCount, _studentAddress, _name);
        studentCount++;
    }

    function updateStudentGrade(
        uint256 _studentId,
        uint8 _newGrade
    ) public onlyPrincipal {
        require(_studentId < studentCount, "Student does not exist");
        require(_newGrade >= 1 && _newGrade <= 12, "Invalid grade");

        students[_studentId].grade = _newGrade;
        emit StudentGradeUpdated(_studentId, _newGrade);
    }

    function updateStudentStatus(
        uint256 _studentId,
        Status _newStatus
    ) public onlyPrincipal {
        require(_studentId < studentCount, "Student does not exist");
        students[_studentId].status = _newStatus;
    }

    function addScoreToStudent(
        uint256 _studentId,
        string memory _subject,
        uint8 _score
    ) public onlyPrincipalOrTeacher {
        require(_studentId < studentCount, "Student does not exist");
        require(_score <= 100, "Score cannot exceed 100");
        require(bytes(_subject).length > 0, "Subject cannot be empty");

        // Check if subject already exists for this student
        bool subjectExists = false;
        for (uint i = 0; i < students[_studentId].subjects.length; i++) {
            if (
                keccak256(bytes(students[_studentId].subjects[i])) ==
                keccak256(bytes(_subject))
            ) {
                subjectExists = true;
                break;
            }
        }

        // If subject doesn't exist, add it to the subjects array
        if (!subjectExists) {
            students[_studentId].subjects.push(_subject);
        }

        students[_studentId].scores[_subject] = _score;
        emit ScoreUpdated(_studentId, _subject, _score, msg.sender);
    }

    function getStudentScore(
        uint256 _studentId,
        string memory _subject
    ) public view returns (uint8) {
        require(_studentId < studentCount, "Student does not exist");
        return students[_studentId].scores[_subject];
    }

    function getStudentSubjects(
        uint256 _studentId
    ) public view returns (string[] memory) {
        require(_studentId < studentCount, "Student does not exist");
        return students[_studentId].subjects;
    }

    // ==================== TEACHER FUNCTIONS ====================

    function addTeacher(
        address _teacherAddress,
        string memory _name,
        uint8 _age,
        Gender _gender,
        string memory _subject,
        uint256 _salary
    ) public onlyPrincipal {
        require(_teacherAddress != address(0), "Invalid teacher address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!isTeacher[_teacherAddress], "Teacher already exists");
        require(_age > 18 && _age < 100, "Invalid age for teacher");
        require(bytes(_subject).length > 0, "Subject cannot be empty");
        require(_salary > 0, "Salary must be greater than 0");

        teachers[teacherCount] = Teacher({
            teacherAddress: _teacherAddress,
            name: _name,
            age: _age,
            gender: _gender,
            subject: _subject,
            status: TeacherStatus.active,
            salary: _salary,
            hireDate: block.timestamp
        });

        teacherAddressToId[_teacherAddress] = teacherCount;
        isTeacher[_teacherAddress] = true;

        emit TeacherAdded(teacherCount, _teacherAddress, _name, _subject);
        teacherCount++;
    }

    function updateTeacherStatus(
        uint256 _teacherId,
        TeacherStatus _newStatus
    ) public onlyPrincipal {
        require(_teacherId < teacherCount, "Teacher does not exist");
        teachers[_teacherId].status = _newStatus;
        emit TeacherStatusUpdated(_teacherId, _newStatus);
    }

    function updateTeacherSalary(
        uint256 _teacherId,
        uint256 _newSalary
    ) public onlyPrincipal {
        require(_teacherId < teacherCount, "Teacher does not exist");
        require(_newSalary > 0, "Salary must be greater than 0");
        teachers[_teacherId].salary = _newSalary;
    }

    function removeTeacher(uint256 _teacherId) public onlyPrincipal {
        require(_teacherId < teacherCount, "Teacher does not exist");
        address teacherAddress = teachers[_teacherId].teacherAddress;

        teachers[_teacherId].status = TeacherStatus.inactive;
        isTeacher[teacherAddress] = false;
    }

    function getTeacher(
        uint256 _teacherId
    )
        public
        view
        returns (
            address teacherAddress,
            string memory name,
            uint8 age,
            Gender gender,
            string memory subject,
            TeacherStatus status,
            uint256 salary,
            uint256 hireDate
        )
    {
        require(_teacherId < teacherCount, "Teacher does not exist");
        Teacher memory teacher = teachers[_teacherId];
        return (
            teacher.teacherAddress,
            teacher.name,
            teacher.age,
            teacher.gender,
            teacher.subject,
            teacher.status,
            teacher.salary,
            teacher.hireDate
        );
    }

    // ==================== VIEW FUNCTIONS ====================

    function getAllStudents()
        public
        view
        returns (
            address[] memory addresses,
            string[] memory names,
            uint8[] memory ages,
            uint8[] memory grades,
            Gender[] memory genders,
            Status[] memory statuses
        )
    {
        addresses = new address[](studentCount);
        names = new string[](studentCount);
        ages = new uint8[](studentCount);
        grades = new uint8[](studentCount);
        genders = new Gender[](studentCount);
        statuses = new Status[](studentCount);

        for (uint256 i = 0; i < studentCount; i++) {
            addresses[i] = students[i].studentAddress;
            names[i] = students[i].name;
            ages[i] = students[i].age;
            grades[i] = students[i].grade;
            genders[i] = students[i].gender;
            statuses[i] = students[i].status;
        }
    }

    function getAllTeachers()
        public
        view
        returns (
            address[] memory addresses,
            string[] memory names,
            uint8[] memory ages,
            Gender[] memory genders,
            string[] memory subjects,
            TeacherStatus[] memory statuses,
            uint256[] memory salaries
        )
    {
        addresses = new address[](teacherCount);
        names = new string[](teacherCount);
        ages = new uint8[](teacherCount);
        genders = new Gender[](teacherCount);
        subjects = new string[](teacherCount);
        statuses = new TeacherStatus[](teacherCount);
        salaries = new uint256[](teacherCount);

        for (uint256 i = 0; i < teacherCount; i++) {
            addresses[i] = teachers[i].teacherAddress;
            names[i] = teachers[i].name;
            ages[i] = teachers[i].age;
            genders[i] = teachers[i].gender;
            subjects[i] = teachers[i].subject;
            statuses[i] = teachers[i].status;
            salaries[i] = teachers[i].salary;
        }
    }

    function getStudent(
        uint256 _studentId
    )
        public
        view
        returns (
            address studentAddress,
            string memory name,
            uint8 age,
            uint8 grade,
            Gender gender,
            Status status
        )
    {
        require(_studentId < studentCount, "Student does not exist");
        Student storage student = students[_studentId];
        return (
            student.studentAddress,
            student.name,
            student.age,
            student.grade,
            student.gender,
            student.status
        );
    }

    function getActiveStudentsCount() public view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < studentCount; i++) {
            if (students[i].status == Status.active) {
                activeCount++;
            }
        }
        return activeCount;
    }

    function getActiveTeachersCount() public view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < teacherCount; i++) {
            if (teachers[i].status == TeacherStatus.active) {
                activeCount++;
            }
        }
        return activeCount;
    }

    // ==================== UTILITY FUNCTIONS ====================

    function changePrincipal(address _newPrincipal) public onlyPrincipal {
        require(_newPrincipal != address(0), "Invalid principal address");
        principal = _newPrincipal;
    }

    function getStudentIdByAddress(
        address _studentAddress
    ) public view returns (uint256) {
        require(
            isStudent[_studentAddress],
            "Address is not a registered student"
        );
        return studentAddressToId[_studentAddress];
    }

    function getTeacherIdByAddress(
        address _teacherAddress
    ) public view returns (uint256) {
        require(
            isTeacher[_teacherAddress],
            "Address is not a registered teacher"
        );
        return teacherAddressToId[_teacherAddress];
    }
}
