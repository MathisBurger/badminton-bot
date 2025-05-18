export interface Account {
    username: string;
    password: string;
}

export interface Course {
    cron: string;
    courseId: number;
}

export interface Config {
    accounts: Account[];
    courses: Course[];
}
