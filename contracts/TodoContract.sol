// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TodoContract {
    struct Task {
        uint256 id;
        string title;
        string description;
        bool completed;
        uint256 createdAt;
        address owner;
    }

    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks;
    uint256 public nextTaskId;

    // Events
    event TaskCreated(
        uint256 indexed taskId,
        address indexed owner,
        string title,
        string description,
        uint256 createdAt
    );

    event TaskCompleted(uint256 indexed taskId, address indexed owner);

    event TaskDeleted(uint256 indexed taskId, address indexed owner);

    event TaskUpdated(
        uint256 indexed taskId,
        address indexed owner,
        string title,
        string description
    );

    modifier onlyTaskOwner(uint256 _taskId) {
        require(tasks[_taskId].owner == msg.sender, "Not the task owner");
        require(tasks[_taskId].id != 0, "Task does not exist");
        _;
    }

    // Create a new task
    function createTask(
        string memory _title,
        string memory _description
    ) external {
        uint256 taskId = nextTaskId++;

        tasks[taskId] = Task({
            id: taskId,
            title: _title,
            description: _description,
            completed: false,
            createdAt: block.timestamp,
            owner: msg.sender
        });

        userTasks[msg.sender].push(taskId);

        emit TaskCreated(
            taskId,
            msg.sender,
            _title,
            _description,
            block.timestamp
        );
    }

    // Mark task as completed
    function completeTask(uint256 _taskId) external onlyTaskOwner(_taskId) {
        require(!tasks[_taskId].completed, "Task already completed");

        tasks[_taskId].completed = true;

        emit TaskCompleted(_taskId, msg.sender);
    }

    // Update task title and description
    function updateTask(
        uint256 _taskId,
        string memory _title,
        string memory _description
    ) external onlyTaskOwner(_taskId) {
        tasks[_taskId].title = _title;
        tasks[_taskId].description = _description;

        emit TaskUpdated(_taskId, msg.sender, _title, _description);
    }

    // Delete a task
    function deleteTask(uint256 _taskId) external onlyTaskOwner(_taskId) {
        // Remove from user's task list
        uint256[] storage userTaskList = userTasks[msg.sender];
        for (uint256 i = 0; i < userTaskList.length; i++) {
            if (userTaskList[i] == _taskId) {
                userTaskList[i] = userTaskList[userTaskList.length - 1];
                userTaskList.pop();
                break;
            }
        }

        delete tasks[_taskId];

        emit TaskDeleted(_taskId, msg.sender);
    }

    // Get all tasks for a user
    function getUserTasks(address _user) external view returns (Task[] memory) {
        uint256[] memory taskIds = userTasks[_user];
        Task[] memory userTaskList = new Task[](taskIds.length);

        uint256 validTasks = 0;
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (tasks[taskIds[i]].id != 0) {
                userTaskList[validTasks] = tasks[taskIds[i]];
                validTasks++;
            }
        }

        // Resize array to remove empty slots
        Task[] memory result = new Task[](validTasks);
        for (uint256 i = 0; i < validTasks; i++) {
            result[i] = userTaskList[i];
        }

        return result;
    }

    // Get task count for a user
    function getUserTaskCount(address _user) external view returns (uint256) {
        return userTasks[_user].length;
    }

    // Get task by ID
    function getTask(uint256 _taskId) external view returns (Task memory) {
        require(tasks[_taskId].id != 0, "Task does not exist");
        return tasks[_taskId];
    }

    // Get total number of tasks created
    function getTotalTasks() external view returns (uint256) {
        return nextTaskId;
    }
}
