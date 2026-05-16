import { Injectable, NotFoundException } from '@nestjs/common';
import { Article } from 'src/entities/article.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateArticle } from './interfaces/create-article';
import { UpdateArticle } from './interfaces/update-article';

@Injectable()
export class ArticlesService {
    constructor(
        @InjectRepository(Article) private articleRepo: Repository<Article>,
    ) {}

    findAll() {
        return this.articleRepo.find();
    }

    async findOne(id: number) {
        const res = await this.articleRepo.findOne({ where: { id: id } });
        if (!res) {
            throw new NotFoundException('Id not found');
        }
        return res;
    }

    async create(data: CreateArticle) {
        const article = this.articleRepo.create(data);
        return await this.articleRepo.save(article);
    }

    async update(id: number, data: UpdateArticle) {
        const article = await this.findOne(id);
        if (!article) {
            throw new NotFoundException('Article not found');
        }

        await this.articleRepo.update(id, data);
        return await this.findOne(id);
    }

    async remove(id: number) {
        const article = await this.findOne(id);
        if (!article) {
            throw new NotFoundException('Article not found');
        }
        await this.articleRepo.delete(id);
        return { success: true };
    }
}
