package com.yuuuzzzin.offoff_android.database.repository

import com.yuuuzzzin.offoff_android.database.dao.ShiftDao
import com.yuuuzzzin.offoff_android.database.models.Shift
import io.realm.Realm
import javax.inject.Inject

/* 뷰모델은 비즈니스 로직에 집중할 수 있도록 db 작업은 리포지토리를 거쳐 수행
* ViewModel <-> Repository <-> DAO
*/

class ScheduleDataBaseRepository @Inject
constructor(
    private val shiftDao: ShiftDao, private val realm: Realm
) {

    // 저장된 모든 근무타입
    val shiftList = shiftDao.getAllShifts()

    // 모든 근무타입 라이브데이터로 가져오기
    fun getAllShifts() = shiftDao.getAllShifts()

    // 모든 근무타입 가져오기
    fun getAllShift() = shiftDao.getAllShift()

    // 근무타입 추가
    fun insertShift(shift: Shift) = shiftDao.insertShift(shift)

    // 특정 근무타입 삭제
    fun deleteShift(id: String) = shiftDao.deleteShift(id)

    // 모든 근무타입 삭제
    fun deleteAllShifts() = shiftDao.deleteAllShifts()

    // id max 값 + 1 반환하는 메소드
    fun getNextId(): Int = shiftDao.getNextId()
}